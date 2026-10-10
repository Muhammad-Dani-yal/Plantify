const fs = require('node:fs');
const path = require('node:path');
const entries = JSON.parse(fs.readFileSync('tool/catalogue.json', 'utf8'));
const existingImage = id => ['webp', 'jpg']
  .map(extension => `assets/catalogue/${id}.${extension}`)
  .find(file => fs.existsSync(file)) || '';
const profiles = {
  foliage: ['Indoor','Tropical','Indirect','Moderate',7,'Easy','18–28°C','Airy houseplant compost with perlite.','Let the upper soil dry slightly; keep light bright but filtered.'],
  tropical: ['Indoor','Statement leaves','Indirect','Moderate',5,'Moderate','18–28°C','Moisture-retentive but well-draining houseplant mix.','Keep humidity steady and protect delicate leaves from hot direct sun.'],
  shade: ['Indoor','Low-light lovers','Low light','Moderate',10,'Easy','18–27°C','Well-draining houseplant compost.','Low light slows growth and water use. Check soil and avoid leaving the pot wet.'],
  'dry-foliage': ['Indoor','Easy care','Indirect','Low',14,'Easy','18–28°C','Free-draining houseplant compost.','Allow much of the potting mix to dry between watering; avoid standing water.'],
  trailing: ['Indoor','Trailing','Indirect','Moderate',7,'Easy','18–28°C','Airy, well-draining houseplant mix.','Train stems on a support or let them trail. Rotate the pot for even light.'],
  climber: ['Indoor','Climbers','Indirect','Moderate',7,'Easy','18–28°C','Chunky potting mix with bark and perlite.','Offer a climbing support and allow the top layer of soil to dry before watering.'],
  palm: ['Indoor','Palms','Indirect','Moderate',7,'Moderate','18–27°C','Well-draining houseplant mix with organic matter.','Keep soil lightly moist rather than soggy; protect fronds from drying drafts.'],
  fern: ['Indoor','Ferns','Indirect','Moderate',4,'Moderate','16–25°C','Loose moisture-retentive fern or houseplant compost.','Check moisture often and provide humid air. Avoid allowing the entire root ball to dry.'],
  epiphyte: ['Indoor','Ferns','Indirect','Moderate',7,'Moderate','16–27°C','Loose bark-based epiphyte mix or a suitable mounted support.','Moisten the root support when it begins to dry. Do not bury the crown in heavy compost.'],
  prayer: ['Indoor','Patterned leaves','Indirect','Moderate',5,'Moderate','18–27°C','Airy moisture-retentive potting mix.','Maintain even moisture and humidity. Filtered water can help where tap water is very hard.'],
  succulent: ['Indoor','Succulents','Full sun','Low',14,'Easy','15–28°C','Gritty cactus and succulent mix.','Give plenty of light and allow the potting mix to dry before watering. Acclimatise to direct sun.'],
  'succulent-trailing': ['Indoor','Trailing','Indirect','Low',14,'Moderate','15–28°C','Gritty, rapidly draining succulent mix.','Give bright light and let compost dry. Keep the crown airy and avoid water trapped in foliage.'],
  'hardy-succulent': ['Outdoor','Succulents','Full sun','Low',14,'Easy','Outdoors; frost hardy','Gritty, sharply drained compost.','Protect from persistent wet conditions. Outdoor rainfall often provides enough moisture.'],
  cactus: ['Indoor','Cacti','Full sun','Low',21,'Easy','15–30°C','Very free-draining cactus mix.','Introduce strong sun gradually and keep much drier during cool dormant periods. Handle spines carefully.'],
  'forest-cactus': ['Indoor','Cacti','Indirect','Moderate',7,'Easy','16–26°C','Loose bark-enriched cactus mix.','These forest cacti prefer filtered light and more moisture than desert cacti. Avoid waterlogging.'],
  flowering: ['Indoor','Flowering','Indirect','Moderate',7,'Moderate','16–25°C','Well-draining compost appropriate to flowering houseplants.','Give bright filtered light. Keep flowers dry and adjust watering as growth slows.'],
  'cool-flowering': ['Indoor','Flowering','Indirect','Moderate',5,'Moderate','10–18°C','Free-draining flowering plant compost.','Keep cool while flowering. Water around the edge of the pot and reduce water as the plant becomes dormant.'],
  bromeliad: ['Indoor','Flowering','Indirect','Moderate',7,'Moderate','18–28°C','Loose bromeliad or orchid-style mix.','Use soft water, refresh the central cup regularly, and avoid constantly soggy roots.'],
  orchid: ['Indoor','Orchids','Indirect','Moderate',7,'Moderate','16–28°C','Orchid bark; do not use ordinary dense potting soil.','Inspect the bark and roots before watering. Drain completely and give gentle air movement.'],
  herb: ['Outdoor','Herbs','Full sun','Moderate',3,'Easy','Seasonal outdoors','Well-draining container compost.','Grow in a bright spot, check small pots frequently, and harvest lightly to encourage fresh growth.'],
  'dry-herb': ['Outdoor','Herbs','Full sun','Low',7,'Easy','Sunny outdoors','Gritty, well-drained container compost.','Offer strong light and airy conditions. Let the upper compost dry and avoid rich wet soil.'],
  'outdoor-flower': ['Outdoor','Flowering','Full sun','Moderate',3,'Moderate','Seasonal outdoors','Well-draining container compost suited to the species.','Check containers often in hot weather. Flowering and winter protection depend on your local climate.'],
  'outdoor-climber': ['Outdoor','Climbers','Full sun','Moderate',5,'Moderate','Mild outdoors','Well-draining container compost.','Provide a sturdy climbing support. Protect tender growth from frost and adjust water to the season.'],
  'outdoor-shade': ['Outdoor','Flowering','Indirect','Moderate',3,'Moderate','Sheltered outdoors','Moisture-retentive, well-drained acidic compost where required.','Choose a sheltered spot with filtered sun. Avoid letting roots dry completely in warm weather.'],
};
const wikiOverrides = {'alocasia':'Alocasia × amazonica','christmas-cactus':'Schlumbergera','amaryllis':'Hippeastrum','petunia':'Petunia × atkinsiana','umbrella':'Schefflera actinophylla','dwarf-umbrella':'Schefflera arboricola','areca':'Dypsis lutescens','moon-cactus':'Gymnocalycium mihanovichii','rattlesnake':'Goeppertia insignis','begonia':'Begonia rex'};
const userAgent = 'Plantify/1.0 (educational botanical catalogue; Wikimedia attribution preserved)';
async function get(url, attempt = 0) {
  await new Promise(resolve => setTimeout(resolve, 700));
  const r = await fetch(url, {headers:{'User-Agent':userAgent}, signal:AbortSignal.timeout(45000)});
  if ((r.status === 429 || r.status >= 500) && attempt < 4) {
    await new Promise(resolve => setTimeout(resolve, 15000 * (attempt + 1))); return get(url, attempt + 1);
  }
  if (!r.ok) throw new Error(`${r.status} ${url.split('?')[0]}`);
  return r;
}
async function api(host, params) {
  return (await get(`https://${host}/w/api.php?${new URLSearchParams({...params,format:'json',origin:'*'})}`)).json();
}
const dartString = s => "'" + s.replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/\$/g,'\\$').replace(/\n/g,'\\n') + "'";
async function main() {
  fs.mkdirSync('assets/catalogue',{recursive:true});
  const creditFile = 'assets/catalogue/credits.json';
  const credits = fs.existsSync(creditFile) ? JSON.parse(fs.readFileSync(creditFile,'utf8')) : {};
  for (let start=0; start<entries.length; start+=8) {
    const batch = entries.slice(start,start+8);
    if (batch.every(e => credits[e.id] && existingImage(e.id))) continue;
    const response = await api('en.wikipedia.org',{action:'query',titles:batch.map(e=>wikiOverrides[e.id] || e.botanical).join('|'),prop:'pageimages|info',inprop:'url',pithumbsize:'480',redirects:'1'});
    const pages = Object.values(response.query?.pages || {});
    const files = pages.map(p => p.pageimage).filter(Boolean);
    const metadata = files.length ? await api('en.wikipedia.org',{action:'query',titles:files.map(f=>`File:${f}`).join('|'),prop:'imageinfo',iiprop:'url|extmetadata'}) : {};
    const metaPages = Object.values(metadata.query?.pages || {});
    for (const entry of batch) {
      if (credits[entry.id] && existingImage(entry.id)) continue;
      let title = wikiOverrides[entry.id] || entry.botanical;
      for (const red of response.query?.redirects || []) if (red.from === title) title = red.to;
      for (const norm of response.query?.normalized || []) if (norm.from === title) title = norm.to;
      let page = pages.find(p=>p.title === title);
      try {
        let file = page?.pageimage;
        let imageUrl = page?.thumbnail?.source;
        if (!file || !imageUrl) {
          const search = await api('commons.wikimedia.org',{action:'query',generator:'search',gsrsearch:`"${entry.botanical.replace(' x ',' ')}" filetype:bitmap`,gsrnamespace:'6',gsrlimit:'1',prop:'imageinfo',iiprop:'url|extmetadata',iiurlwidth:'480'});
          const match = Object.values(search.query?.pages || {})[0];
          if (match) {file = match.title.replace(/^File:/,''); imageUrl = match.imageinfo?.[0]?.thumburl;}
        }
        if (!file || !imageUrl) throw new Error('No species photo found');
        let info = metaPages.find(p => p.title === `File:${file}`)?.imageinfo?.[0];
        if (!info) {
          const meta = await api('en.wikipedia.org',{action:'query',titles:`File:${file}`,prop:'imageinfo',iiprop:'url|extmetadata'});
          info = Object.values(meta.query?.pages || {})[0]?.imageinfo?.[0];
        }
        if (!info) throw new Error('Photo attribution unavailable');
        const image = await get(imageUrl);
        const bytes = Buffer.from(await image.arrayBuffer());
        if (!image.headers.get('content-type')?.startsWith('image/')) throw new Error('Not an image');
        fs.writeFileSync(`assets/catalogue/${entry.id}.jpg`,bytes);
        const clean = s => (s || '').replace(/<[^>]*>/g,'').replace(/&amp;/g,'&').trim();
        credits[entry.id] = {file,source:info.descriptionurl,author:clean(info.extmetadata?.Artist?.value),license:clean(info.extmetadata?.LicenseShortName?.value),licenseUrl:info.extmetadata?.LicenseUrl?.value || '',article:page?.fullurl || `https://en.wikipedia.org/wiki/${encodeURIComponent(entry.botanical)}`};
        console.log(`${start + batch.indexOf(entry) + 7}/100 ${entry.name}`);
        fs.writeFileSync(creditFile,JSON.stringify(credits,null,2));
      } catch (error) {console.log(`Photo pending: ${entry.name}: ${error.message}`);}
    }
  }
  const colors = ['E1EBD3','EFE0CE','DFE8EB','E5DDED','DEE9DD'];
  const plants = entries.map((entry,i)=>{
    const [environment,category,light,water,waterDays,difficulty,temperature,soil,tip] = profiles[entry.group];
    const image = existingImage(entry.id);
    const credit = credits[entry.id];
    return `  Plant(id: ${dartString(entry.id)}, name: ${dartString(entry.name)}, botanical: ${dartString(entry.botanical)}, image: ${dartString(image)}, environment: ${dartString(environment)}, category: ${dartString(category)}, light: ${dartString(light)}, water: ${dartString(water)}, waterDays: ${waterDays}, difficulty: ${dartString(difficulty)}, temperature: ${dartString(temperature)}, soil: ${dartString(soil)}, tip: ${dartString(tip)}, description: ${dartString(entry.description)}, color: Color(0xFF${colors[i%colors.length]}), imageCredit: ${dartString(credit ? `${credit.author} · ${credit.license}` : '')}, imageSource: ${dartString(credit?.source || '')}),`;
  });
  fs.writeFileSync('lib/data/catalogue.g.dart',`part of 'plants.dart';\n\n// Generated from tool/catalogue.json by tool/build_catalogue.cjs.\nconst extraPlants = <Plant>[\n${plants.join('\n')}\n];\n`);
  const missing = entries.filter(e=>!credits[e.id]);
  console.log(JSON.stringify({total:entries.length+6,photos:entries.length-missing.length,missing:missing.map(e=>e.id)}));
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
