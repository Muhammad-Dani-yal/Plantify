// Firebase Hosting REST deployment using the existing Firebase CLI login.
// Avoids unrelated CLI startup requests; no token is logged or saved.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const zlib = require('node:zlib');
async function main() {
  const auth = require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if(!account) throw new Error('Run firebase login first.');
  const api = require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/api.js'));
  const refreshed = await fetch('https://oauth2.googleapis.com/token', {
    method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:new URLSearchParams({grant_type:'refresh_token',refresh_token:account.tokens.refresh_token,
      client_id:api.clientId(),client_secret:api.clientSecret()}),signal:AbortSignal.timeout(30000)
  });
  const token = await refreshed.json();
  if(!refreshed.ok || !token.access_token) throw new Error('Firebase login refresh failed: '+refreshed.status);
  const headers = {Authorization:`Bearer ${token.access_token}`};
  const root = path.resolve('build/web');
  if(!fs.existsSync(path.join(root,'index.html'))) throw new Error('Build the web app first.');
  async function request(resource,method='GET',body) {
    const response=await fetch('https://firebasehosting.googleapis.com/v1beta1/'+resource,{
      method, headers:{...headers,'Content-Type':'application/json'},
      ...(body ? {body:JSON.stringify(body)} : {}), signal:AbortSignal.timeout(60000)
    });
    const data=await response.json();
    if(!response.ok) throw new Error(`Hosting ${response.status}: ${data.error?.message || 'request failed'}`);
    return data;
  }
  const sites=await request('projects/plantify-00/sites');
  const site=sites.sites?.find(s=>s.name.endsWith('/plantify-00'));
  if(!site) throw new Error('Expected Firebase Hosting site does not exist.');
  const version=await request('projects/-/sites/plantify-00/versions','POST',{
    config:{rewrites:[{glob:'**',path:'/index.html'}]}
  });
  const files={}, buffers=new Map();
  function walk(dir) {
    for(const entry of fs.readdirSync(dir,{withFileTypes:true})) {
      if(entry.name.startsWith('.') || entry.name==='node_modules') continue;
      const file=path.join(dir,entry.name);
      if(entry.isDirectory()) walk(file);
      else {
        const bytes=zlib.gzipSync(fs.readFileSync(file),{level:9});
        const hash=crypto.createHash('sha256').update(bytes).digest('hex');
        files['/'+path.relative(root,file).split(path.sep).join('/')]=hash;
        buffers.set(hash,bytes);
      }
    }
  }
  walk(root);
  const populated=await request(version.name+':populateFiles','POST',{files});
  const hashes=populated.uploadRequiredHashes || [];
  console.log(`Hosting: ${Object.keys(files).length} files, ${hashes.length} uploads required.`);
  let next=0,completed=0;
  await Promise.all(Array.from({length:Math.min(4,hashes.length)},async()=>{
    while(next<hashes.length) {
      const hash=hashes[next++];
      const response=await fetch(populated.uploadUrl+'/'+hash,{
        method:'POST',headers:{...headers,'Content-Type':'application/octet-stream'},
        body:buffers.get(hash),signal:AbortSignal.timeout(120000)
      });
      if(!response.ok) throw new Error('Hosting file upload failed: '+response.status);
      completed++;
      if(completed%30===0 || completed===hashes.length) console.log(`Uploaded ${completed}/${hashes.length}`);
    }
  }));
  await request(version.name+'?updateMask=status','PATCH',{status:'FINALIZED'});
  await request('projects/-/sites/plantify-00/channels/live/releases?versionName='+encodeURIComponent(version.name),'POST',{});
  console.log('Published https://plantify-00.web.app');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
