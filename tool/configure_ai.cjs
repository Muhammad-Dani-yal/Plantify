// Configure the existing project's free-tier Gemini backend. No secret is printed.
const path = require('node:path');
async function main() {
  const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'};
  async function request(url, method = 'GET', body) {
    const r = await fetch(url, {method, headers, ...(body ? {body: JSON.stringify(body)} : {})});
    const data = await r.json();
    if (!r.ok) throw new Error(`${r.status}: ${data.error?.message}`);
    return data;
  }
  for (const service of ['firebasevertexai.googleapis.com', 'generativelanguage.googleapis.com']) {
    const operation = await request(`https://serviceusage.googleapis.com/v1/projects/525947588461/services/${service}:enable`, 'POST', {});
    if (operation.name && !operation.done) {
      for (let i = 0; i < 30; i++) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        const result = await request(`https://serviceusage.googleapis.com/v1/${operation.name}`);
        if (result.error) throw new Error(result.error.message);
        if (result.done) break;
      }
    }
    console.log(`${service}: enabled`);
  }
  const name = 'projects/plantify-00/locations/global/config';
  await request(`https://firebasevertexai.googleapis.com/v1beta/${name}?updateMask=generative_language_config`, 'PATCH',
      {name, generativeLanguageConfig: {}});
  console.log('Firebase AI Gemini backend configured; billing plan unchanged.');
}
main().catch(e => {console.error(e.message); process.exitCode = 1;});
