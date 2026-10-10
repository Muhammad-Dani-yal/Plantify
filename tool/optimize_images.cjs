// Install the encoder: npm install --prefix build/asset-optimizer sharp
// Originals are backed up outside the Flutter asset bundle before conversion.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('../build/asset-optimizer/node_modules/sharp');

async function main() {
  let before = 0, after = 0, count = 0;
  const replacements = new Map();
  for (const folder of ['assets/botanical', 'assets/catalogue']) {
    if (process.argv.includes('--from-originals')) {
      const backupFolder = path.join('build/asset-originals', folder);
      if (fs.existsSync(backupFolder)) {
        for (const name of fs.readdirSync(backupFolder)) {
          if (/\.(png|jpg)$/i.test(name)) {
            fs.copyFileSync(path.join(backupFolder, name), `${folder}/${name}`);
          }
        }
      }
    }
    for (const name of fs.readdirSync(folder)) {
      if (name.endsWith('.webp')) {
        for (const extension of ['png', 'jpg']) {
          replacements.set(`${folder}/${name.replace(/\.webp$/, `.${extension}`)}`, `${folder}/${name}`);
        }
        continue;
      }
      if (!/\.(png|jpg)$/i.test(name)) continue;
      const input = `${folder}/${name}`;
      const output = input.replace(/\.(png|jpg)$/i, '.webp');
      const original = fs.readFileSync(input);
      const metadata = await sharp(original).metadata();
      const limit = folder.endsWith('catalogue') ? 640
          : name.startsWith('greenhouse-hero') ? 1280 : 1024;
      const encoded = await sharp(original)
          .rotate()
          .resize({width: limit, height: limit, fit: 'inside', withoutEnlargement: true})
          .webp({quality: folder.endsWith('catalogue') ? 76 : 84, alphaQuality: 100, effort: 6})
          .toBuffer();
      const result = await sharp(encoded).metadata();
      const lostTransparency = metadata.hasAlpha && !result.hasAlpha &&
          (await sharp(original).stats()).channels.at(-1).min < 255;
      if (result.format !== 'webp' || !result.width || !result.height || lostTransparency) {
        throw new Error(`Invalid optimized image: ${input}`);
      }
      const backup = path.join('build/asset-originals', input);
      fs.mkdirSync(path.dirname(backup), {recursive: true});
      if (!fs.existsSync(backup)) fs.writeFileSync(backup, original);
      fs.writeFileSync(output, encoded);
      fs.unlinkSync(input);
      replacements.set(input, output);
      before += original.length;
      after += encoded.length;
      count++;
    }
  }
  // Keep the app and test asset references in sync with the encoded filenames.
  for (const root of ['lib', 'test']) {
    for (const file of fs.readdirSync(root, {recursive: true})) {
      if (!file.endsWith('.dart')) continue;
      const target = path.join(root, file);
      let content = fs.readFileSync(target, 'utf8');
      for (const [original, optimized] of replacements) {
        content = content.replaceAll(original, optimized);
      }
      content = content.replace('assets/botanical/$image.png', 'assets/botanical/$image.webp');
      if (content !== fs.readFileSync(target, 'utf8')) fs.writeFileSync(target, content);
    }
  }
  console.log(JSON.stringify({images: count, beforeBytes: before, afterBytes: after,
    reductionPercent: before ? +(100 * (1 - after / before)).toFixed(1) : 0}));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
