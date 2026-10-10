// Render the existing vector brand mark into installable web icon sizes.
const {chromium}=require('../build/qa-runner/node_modules/playwright');
const fs=require('node:fs');
async function main(){
  const browser=await chromium.launch({channel:'chrome',headless:true});
  try{
    const page=await browser.newPage();
    const svg=fs.readFileSync('web/plantify.svg','utf8');
    for(const size of [192,512]){
      await page.setViewportSize({width:size,height:size});
      await page.setContent(`<style>html,body{margin:0;background:#183F32}svg{width:100vw;height:100vh}</style>${svg}`);
      await page.screenshot({path:`web/icons/Icon-${size}.png`});
      fs.copyFileSync(`web/icons/Icon-${size}.png`,`web/icons/Icon-maskable-${size}.png`);
    }
    await page.setViewportSize({width:32,height:32});
    await page.screenshot({path:'web/favicon.png'});
  }finally{await browser.close();}
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
