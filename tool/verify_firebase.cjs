// Creates two temporary QA accounts, verifies auth and owner-only data, then deletes them.
// No emails are sent and no existing account data is touched.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const raw = fs.readFileSync('firebase-web-config.json');
const config = JSON.parse(raw.toString(raw[0] === 255 ? 'utf16le' : 'utf8').replace(/^\uFEFF/, '')).result.sdkConfig;
const accounts = [];
async function auth(method, body) {
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${config.apiKey}`, {
    method:'POST', headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const data = await response.json();
  if (!response.ok) throw new Error(`Auth ${method}: ${data.error?.message}`);
  return data;
}
const base = `https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/`;
async function document(method, uid, token, body) {
  return fetch(base+uid, {method,headers:{'Content-Type':'application/json',...(token ? {Authorization:`Bearer ${token}`} : {})},
    ...(body ? {body:JSON.stringify(body)} : {})});
}
async function main() {
  try {
    for (let i=0;i<2;i++) {
      const email = `plantify-qa-${crypto.randomUUID()}@example.invalid`;
      const password = crypto.randomBytes(20).toString('base64url');
      const account = await auth('signUp',{email,password,returnSecureToken:true});
      accounts.push(account);
      const signedIn = await auth('signInWithPassword',{email,password,returnSecureToken:true});
      assert.equal(signedIn.localId,account.localId);
    }
    console.log('PASS: real signup and email/password sign-in.');
    const [owner,other] = accounts;
    const fields = {name:{stringValue:'Plantify QA'},email:{stringValue:owner.email},
      favorites:{arrayValue:{values:[{stringValue:'monstera'}]}},
      garden:{mapValue:{fields:{snake:{mapValue:{fields:{id:{stringValue:'snake'},notes:{stringValue:'QA care note'},watered:{stringValue:new Date().toISOString()}}}}}}}};
    const write = await document('PATCH',owner.localId,owner.idToken,{fields});
    assert.equal(write.status,200,await write.text());
    const read = await document('GET',owner.localId,owner.idToken);
    assert.equal(read.status,200);
    const data = await read.json();
    assert.equal(data.fields.garden.mapValue.fields.snake.mapValue.fields.notes.stringValue,'QA care note');
    console.log('PASS: real Firestore favourites, garden, care notes and watering record.');
    assert.equal((await document('GET',owner.localId,null)).status,403);
    assert.equal((await document('GET',owner.localId,other.idToken)).status,403);
    assert.equal((await document('PATCH',owner.localId,other.idToken,{fields})).status,403);
    console.log('PASS: unauthenticated and cross-account access denied.');
    const worldPath=owner.localId+'/worldPlants/3002479';
    const worldFields={key:{integerValue:'3002479'},canonicalName:{stringValue:'Rosa canina'},scientificName:{stringValue:'Rosa canina L.'},rank:{stringValue:'SPECIES'},taxonomicStatus:{stringValue:'ACCEPTED'},family:{stringValue:'Rosaceae'},genus:{stringValue:'Rosa'}};
    const worldWrite=await document('PATCH',worldPath,owner.idToken,{fields:worldFields});
    assert.equal(worldWrite.status,200,await worldWrite.text());
    assert.equal((await document('GET',worldPath,owner.idToken)).status,200);
    assert.equal((await document('GET',worldPath,null)).status,403);
    assert.equal((await document('GET',worldPath,other.idToken)).status,403);
    assert.equal((await document('PATCH',worldPath,other.idToken,{fields:worldFields})).status,403);
    assert.equal((await document('PATCH',worldPath,owner.idToken,{fields:{...worldFields,unexpected:{stringValue:'invalid'}}})).status,403);
    console.log('PASS: world plant bookmarks persist privately; cross-account and invalid writes denied.');
  } finally {
    for (const account of accounts) {
      const worldRemoved=await document('DELETE',account.localId+'/worldPlants/3002479',account.idToken);
      if(![200,404].includes(worldRemoved.status)) throw new Error('QA world plant cleanup failed.');
      const removed = await document('DELETE',account.localId,account.idToken);
      if (![200,404].includes(removed.status)) throw new Error('QA document cleanup failed.');
      await auth('delete',{idToken:account.idToken});
    }
    console.log('Temporary QA accounts and documents removed.');
  }
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
