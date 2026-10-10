// Uses the already signed-in Firebase CLI account. Never prints credentials.
const fs = require('node:fs');
const path = require('node:path');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
async function main() {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Sign in with firebase login first.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  async function request(url, options = {}) {
    const response = await fetch(url, { ...options, headers: {Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json'} });
    const result = await response.json();
    if (!response.ok) throw new Error(`${response.status}: ${result.error?.message ?? 'Request failed'}`);
    return result;
  }
  const project = 'plantify-00';
  const config = await request(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`);
  console.log(JSON.stringify({emailPasswordEnabled: config.signIn?.email?.enabled, authorizedDomains: config.authorizedDomains}));
  if (process.argv.includes('--enable-auth') && !config.signIn?.email?.enabled) {
    await request(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config?updateMask=signIn.email.enabled,signIn.email.passwordRequired`, {
      method: 'PATCH', body: JSON.stringify({signIn: {email: {enabled: true, passwordRequired: true}}}) });
    console.log('Email/password authentication enabled.');
  }
  const release = await request(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
  const rules = await request(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
  fs.writeFileSync('firestore.previous.rules', rules.source.files.map(f => f.content).join('\n'));
  console.log('Existing Firestore rules backed up to firestore.previous.rules.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
