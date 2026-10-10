// Read-only verification of public GBIF media, attribution, and browser CORS.
const crypto = require('node:crypto');
const fs = require('node:fs');
async function main() {
  for (const name of ['Welwitschia mirabilis', 'Citrus limon', 'Mangifera indica']) {
    const matchUrl = new URL('https://api.gbif.org/v1/species/match');
    matchUrl.searchParams.set('name', name);
    const taxon = await (await fetch(matchUrl, {signal: AbortSignal.timeout(15000)})).json();
    const search = new URL('https://api.gbif.org/v1/occurrence/search');
    for (const [key, value] of Object.entries({taxonKey: String(taxon.usageKey),
      mediaType: 'StillImage', basisOfRecord: 'HUMAN_OBSERVATION', limit: '30',
      license: 'CC_BY_4_0'})) search.searchParams.set(key, value);
    search.searchParams.append('license', 'CC0_1_0');
    const data = await (await fetch(search, {signal: AbortSignal.timeout(15000)})).json();
    let chosen;
    for (const occurrence of data.results ?? []) {
      for (const media of occurrence.media ?? []) {
        if (media.type === 'StillImage' && /^https?:\/\/creativecommons\.org\/(licenses\/(by|by-sa)\/|publicdomain\/zero\/)/.test(media.license ?? '')) {
          chosen = {occurrence, media}; break;
        }
      }
      if (chosen) break;
    }
    if (!chosen) throw new Error(`No reusable test photo for ${name}`);
    const hash = crypto.createHash('md5').update(chosen.media.identifier).digest('hex');
    const image = await fetch(`https://api.gbif.org/v1/image/cache/512x/occurrence/${chosen.occurrence.key}/media/${hash}`,
      {headers: {Origin: 'http://localhost:8765'}, signal: AbortSignal.timeout(20000)});
    const bytes = Buffer.from(await image.arrayBuffer());
    if (!image.ok || !image.headers.get('content-type')?.startsWith('image/')) throw new Error(`Image failed for ${name}: ${image.status}`);
    fs.mkdirSync('build/qa', {recursive: true});
    fs.writeFileSync('build/qa/' + name.replaceAll(' ', '-') + '.jpg', bytes);
    console.log(JSON.stringify({name, imageStatus: image.status, bytes: bytes.length,
      cors: image.headers.get('access-control-allow-origin'), credit: chosen.media.creator ?? chosen.media.rightsHolder,
      license: chosen.media.license}));
  }
}
main().catch(e => {console.error(e.message); process.exitCode = 1;});
