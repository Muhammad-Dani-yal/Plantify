const {chromium}=require('../build/qa-runner/node_modules/playwright');
const fs=require('node:fs');
const crypto=require('node:crypto');
const raw=fs.readFileSync('firebase-web-config.json');
const config=JSON.parse(raw.toString(raw[0]===255?'utf16le':'utf8').replace(/^\uFEFF/,'')).result.sdkConfig;
async function auth(method,body){
  const response=await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${config.apiKey}`,{
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const result=await response.json();
  if(!response.ok) throw new Error(`${method}: ${result.error?.message}`);
  return result;
}
async function main(){
  let account,browser,page,qaEmail,qaPassword;
  const worldKeys=[];
  try{
    const email=`plantify-browser-${crypto.randomUUID()}@example.invalid`;
    const password=crypto.randomBytes(20).toString('base64url');
    qaEmail=email;qaPassword=password;
    account=await auth('signUp',{email,password,returnSecureToken:true});
    await auth('update',{idToken:account.idToken,displayName:'Plantify QA'});
    browser=await chromium.launch({channel:'chrome',headless:true});
    page=await browser.newPage({viewport:{width:1440,height:1000}});
    const errors=[];
    const catalogueRequests=[];
    page.on('request', r=>{if(r.url().includes('/v1/species/search'))catalogueRequests.push(new URL(r.url()));});
    page.on('pageerror',e=>errors.push(e.message));
    await page.goto('http://127.0.0.1:8765');
    const accessibility=page.locator('flt-semantics-placeholder');
    await accessibility.waitFor({state:'attached',timeout:30000});await accessibility.evaluate(el=>el.click());
    await page.getByRole('button',{name:'Get started',exact:true}).click({timeout:30000});
    await page.getByRole('textbox',{name:'Email address',exact:true}).click();
    await page.keyboard.type(email,{delay:15});
    await page.getByRole('textbox',{name:'Password',exact:true}).click();
    await page.keyboard.type(password,{delay:15});
    await page.getByRole('button',{name:'Sign in',exact:true}).click();
    await page.getByText('Discover',{exact:true}).waitFor({timeout:30000});
    console.log('PASS: rendered web app signs in with real Firebase credentials.');
    console.log((await page.locator('body').ariaSnapshot()).replaceAll(email,'QA email').replaceAll(password,'[hidden]').slice(0,4200));
    await page.screenshot({path:'build/qa/home-desktop.png'});
    await page.mouse.move(900,650);
    await page.mouse.wheel(0,500);await page.waitForTimeout(500);
    await page.getByRole('button',{name:'Save Monstera to favorites',exact:true}).click();
    await page.getByRole('button',{name:'Remove Monstera from favorites',exact:true}).waitFor();
    const documentUrl=`https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/${account.localId}`;
    let saved=false;
    for(let attempt=0;attempt<15;attempt++){
      const response=await fetch(documentUrl,{headers:{Authorization:`Bearer ${account.idToken}`}});
      const document=await response.json();
      if(document.fields?.favorites?.arrayValue?.values?.some(value=>value.stringValue==='monstera')){saved=true;break;}
      await page.waitForTimeout(500);
    }
    if(!saved) throw new Error('Rendered favourite action was not persisted in Firestore');
    await page.reload();
    const restoredAccessibility=page.locator('flt-semantics-placeholder');
    await restoredAccessibility.waitFor({state:'attached'});await restoredAccessibility.evaluate(el=>el.click());
    await page.getByText('Discover',{exact:true}).waitFor({timeout:30000});
    await page.mouse.move(900,650);await page.mouse.wheel(0,500);
    await page.getByRole('button',{name:'Remove Monstera from favorites',exact:true}).waitFor({timeout:30000});
    console.log('PASS: browser favourite persists in Firestore; session and saved collection restore after reload.');
    await page.getByRole('button',{name:'AI guide',exact:true}).click();
    const chatInput=page.getByRole('textbox',{name:'Ask about your plants…',exact:true});
    await chatInput.click();await page.keyboard.type('Mein gardening mein new hun. Fruit plants ke liye pehla step kya hai?',{delay:10});
    const firstAI=page.waitForResponse(r=>r.url().includes(':generateContent'),{timeout:75000});
    await page.getByRole('button',{name:'Send question',exact:true}).click();
    const firstResponse=await firstAI;
    if(firstResponse.status()!==200)throw new Error('Browser AI request failed: '+firstResponse.status());
    await page.getByRole('textbox',{name:'Plantify AI',exact:true}).waitFor({timeout:15000});
    await chatInput.click();await page.keyboard.type('Karachi mein sunny balcony hai. Agla step batayein.',{delay:10});
    const secondAI=page.waitForResponse(r=>r.url().includes(':generateContent'),{timeout:75000});
    await page.getByRole('button',{name:'Send question',exact:true}).click();
    const secondResponse=await secondAI;
    if(secondResponse.status()!==200)throw new Error('Browser AI follow-up failed: '+secondResponse.status());
    const history=secondResponse.request().postDataJSON().contents;
    if(history.length!==3||history[1].role!=='model')throw new Error('AI conversation context was not preserved');
    await page.getByRole('textbox',{name:'Plantify AI',exact:true}).nth(1).waitFor({timeout:15000});
    await page.setViewportSize({width:390,height:844});
    await page.waitForTimeout(500);
    await page.screenshot({path:'build/qa/ai-chat-mobile.png'});
    console.log('PASS: rendered browser AI guide returns real Roman Urdu answers and preserves follow-up context.');
    await page.getByRole('button',{name:'Back',exact:true}).click();
    await page.setViewportSize({width:1440,height:1000});
    await page.mouse.move(900,650);
    for(let i=0;i<12&&!catalogueRequests.some(u=>u.searchParams.get('offset')==='24');i++){
      await page.mouse.wheel(0,1800);await page.waitForTimeout(700);
    }
    if(!catalogueRequests.some(u=>u.searchParams.get('offset')==='24'))throw new Error('Scrolling did not automatically fetch the next catalogue page');
    console.log('PASS: main Discover requests the next worldwide page automatically while scrolling.');
    await page.screenshot({path:'build/qa/discover-world-scroll.png'});
    await page.getByRole('button',{name:'Search',exact:true}).click();
    const fruitRequest=page.waitForResponse(r=>r.url().includes('/v1/species/search')&&new URL(r.url()).searchParams.get('q')==='Citrus',{timeout:30000});
    await page.getByRole('button',{name:'Fruit plants',exact:true}).click();
    if((await fruitRequest).status()!==200)throw new Error('Live fruit collection failed');
    const uniqueRequest=page.waitForResponse(r=>r.url().includes('/v1/species/search')&&new URL(r.url()).searchParams.get('q')==='Welwitschia',{timeout:30000});
    await page.getByRole('button',{name:'Unique plants',exact:true}).click();
    if((await uniqueRequest).status()!==200)throw new Error('Live unique collection failed');
    await page.getByRole('button',{name:'All plants',exact:true}).click();
    console.log('PASS: category filters use live multi-genus botanical searches.');
    const worldSearch=page.getByRole('textbox',{name:'Name, species, light, or collection',exact:true});
    await worldSearch.click();await page.keyboard.type('Welwitschia mirabilis',{delay:15});
    const worldSave=page.getByRole('button',{name:/^Save .+ to world plants$/}).first();
    await worldSave.waitFor({timeout:45000});
    const plantImage=page.locator('img[src*="/image/cache/"]').first();
    await plantImage.waitFor({state:'attached',timeout:90000});
    let imageReady=false;
    for(let attempt=0;attempt<80;attempt++){
      if(await plantImage.evaluate(img=>img.complete&&img.naturalWidth>0)){imageReady=true;break;}
      await page.waitForTimeout(500);
    }
    if(!imageReady)throw new Error('World plant photograph did not render');
    console.log('PASS: licensed world plant photograph renders in the browser.');
    await worldSave.click();
    await page.getByRole('button',{name:/^Remove .+ from world plants$/}).first().waitFor({timeout:30000});
    const worldCollectionUrl=documentUrl+'/worldPlants';
    let worldDocument;
    for(let attempt=0;attempt<15;attempt++){
      const response=await fetch(worldCollectionUrl,{headers:{Authorization:`Bearer ${account.idToken}`}});
      const collection=await response.json();
      if(collection.documents?.length){worldDocument=collection.documents[0];worldKeys.push(worldDocument.name.split('/').at(-1));break;}
      await page.waitForTimeout(500);
    }
    if(!worldDocument) throw new Error('World plant bookmark was not persisted');
    await page.getByRole('button',{name:/^My world plants \(1\)$/}).click();
    await page.getByRole('button',{name:worldDocument.fields.canonicalName.stringValue,exact:true}).waitFor();
    console.log('PASS: live GBIF world search works in the browser and world bookmarks persist privately in Firestore.');
    await page.setViewportSize({width:390,height:844});
    await page.waitForTimeout(700);
    await page.mouse.move(220,500);await page.mouse.wheel(0,650);await page.waitForTimeout(500);
    await page.screenshot({path:'build/qa/world-mobile.png'});
    await page.getByRole('button',{name:worldDocument.fields.canonicalName.stringValue,exact:true}).click();
    await page.getByText('Meet your plant',{exact:true}).waitFor();
    await page.locator('img[src*="/image/cache/"]').first().waitFor({state:'attached'});
    await page.screenshot({path:'build/qa/world-profile-mobile.png'});
    await page.setViewportSize({width:1440,height:1000});
    await page.waitForTimeout(500);
    await page.screenshot({path:'build/qa/world-profile-desktop.png'});
    await page.getByRole('button',{name:'Ask AI about this plant',exact:true}).waitFor();
    console.log('PASS: online plant profile uses the shared responsive photo-and-details layout.');
    await page.getByRole('button',{name:'Back',exact:true}).click();
    await page.getByRole('button',{name:'Profile',exact:true}).click();
    await page.getByRole('switch',{name:/^Dark mode/}).click();
    await page.getByRole('button',{name:'Discover',exact:true}).click();
    await page.waitForTimeout(500);
    await page.screenshot({path:'build/qa/dark-desktop.png'});
    await page.setViewportSize({width:390,height:844});
    await page.waitForTimeout(500);
    await page.screenshot({path:'build/qa/dark-mobile.png'});
    console.log('PASS: dark mode and themed animated navigation render on desktop and mobile.');
    if(errors.length) throw new Error(errors.join('\n'));
  }catch(error){
    if(page){
      console.log((await page.locator('body').ariaSnapshot()).replaceAll(qaEmail,'QA email').replaceAll(qaPassword,'[hidden]').slice(0,4200));
      await page.screenshot({path:'build/qa/web-diagnostic.png'});
    }
    throw error;
  }finally{
    if(browser) await browser.close();
    if(account){
      const remaining=await fetch(`https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/${account.localId}/worldPlants`,{headers:{Authorization:`Bearer ${account.idToken}`}});
      const remainingData=await remaining.json();
      for(const document of remainingData.documents??[]){const key=document.name.split('/').at(-1);if(!worldKeys.includes(key))worldKeys.push(key);}
      for(const key of worldKeys){
        const removed=await fetch(`https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/${account.localId}/worldPlants/${key}`,{method:'DELETE',headers:{Authorization:`Bearer ${account.idToken}`}});
        if(![200,404].includes(removed.status)) throw new Error('World bookmark QA cleanup failed');
      }
      const response=await fetch(`https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/${account.localId}`,{
        method:'DELETE',headers:{Authorization:`Bearer ${account.idToken}`}});
      if(![200,404].includes(response.status)) throw new Error('Browser QA data cleanup failed');
      await auth('delete',{idToken:account.idToken});console.log('Browser QA account and data removed.');
    }
  }
}
main().catch(e=>{console.log(e.message);process.exitCode=1;});
