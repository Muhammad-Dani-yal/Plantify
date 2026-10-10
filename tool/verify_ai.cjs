// One real Roman Urdu gardening request through Firebase AI, then account cleanup.
const fs = require('node:fs');
const crypto = require('node:crypto');
const raw = fs.readFileSync('firebase-web-config.json');
const config = JSON.parse(raw.toString(raw[0] === 255 ? 'utf16le' : 'utf8').replace(/^\uFEFF/, '')).result.sdkConfig;
async function auth(method, body) {
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${config.apiKey}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)});
  const data = await response.json();
  if (!response.ok) throw new Error(`Auth ${response.status}`);
  return data;
}
async function main() {
  let account;
  try {
    account = await auth('signUp', {email: `plantify-ai-${crypto.randomUUID()}@example.invalid`,
      password: crypto.randomBytes(20).toString('base64url'), returnSecureToken: true});
    const response = await fetch(`https://firebasevertexai.googleapis.com/v1beta/projects/${config.projectId}/models/gemini-3.5-flash-lite:generateContent`, {
      method: 'POST', headers: {'Content-Type': 'application/json',
        'x-goog-api-key': config.apiKey, 'X-Firebase-AppId': config.appId,
        Authorization: `Firebase ${account.idToken}`},
      body: JSON.stringify({generationConfig: {maxOutputTokens: 800},
        systemInstruction: {parts: [{text: 'You are a concise gardening guide. Reply in Roman Urdu; ask about climate and space before recommending fruit plants.'}]},
        contents: [{role: 'user', parts: [{text: 'Mein gardening mein new hun. Fruit plants ugana chahta hun. Pehla step kya hai?'}]}]}),
      signal: AbortSignal.timeout(60000)});
    const data = await response.json();
    if (!response.ok) throw new Error(`Firebase AI ${response.status}: ${data.error?.message}`);
    const answer = data.candidates?.[0]?.content?.parts?.filter(p => p.text && !p.thought).map(p => p.text).join('\n');
    if (!answer?.trim()) throw new Error('No visible AI answer');
    console.log('PASS: real Firebase AI response, ' + answer.length + ' characters.');
    console.log(answer.slice(0, 650));
  } finally {
    if (account) await auth('delete', {idToken: account.idToken});
  }
}
main().catch(e => {console.error(e.message); process.exitCode = 1;});
