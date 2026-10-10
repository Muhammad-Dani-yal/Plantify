// Update only this repository's Website field using the existing Git login.
// Credentials stay in memory and are never logged or written to disk.
const {spawnSync} = require('node:child_process');
async function main() {
  const result = spawnSync('git', ['credential', 'fill'], {
    input: 'protocol=https\nhost=github.com\n\n', encoding:'utf8',
    windowsHide:true
  });
  if(result.status !== 0) throw new Error('GitHub authentication unavailable.');
  const credentials = Object.fromEntries(result.stdout.trim().split(/\r?\n/).map(line=>{
    const split=line.indexOf('='); return [line.slice(0,split),line.slice(split+1)];
  }));
  if(!credentials.password) throw new Error('GitHub credential unavailable.');
  const headers = {Authorization:`Bearer ${credentials.password}`,Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'};
  const identity = await fetch('https://api.github.com/user',{headers});
  if(!identity.ok || (await identity.json()).login.toLowerCase() !== 'muhammad-dani-yal') throw new Error('Expected repository owner login is required.');
  const response = await fetch('https://api.github.com/repos/Muhammad-Dani-yal/Plantify',{
    method:'PATCH',headers:{...headers,'Content-Type':'application/json'},
    body:JSON.stringify({homepage:'https://plantify-00.web.app'})
  });
  if(!response.ok) throw new Error('Repository Website update failed: '+response.status);
  console.log('Repository Website: '+(await response.json()).homepage);
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
