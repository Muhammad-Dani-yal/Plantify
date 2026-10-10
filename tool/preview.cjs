const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve('build/web');
const types = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg','.svg':'image/svg+xml','.ttf':'font/ttf'};
http.createServer((request,response)=>{
  const pathname = decodeURIComponent(new URL(request.url,'http://localhost').pathname);
  let file = path.resolve(root,'.'+pathname);
  if(!file.startsWith(root+path.sep) && file!==root){response.writeHead(403);response.end();return;}
  if(file===root || !fs.existsSync(file)) file=path.join(root,'index.html');
  if(fs.statSync(file).isDirectory()) file=path.join(file,'index.html');
  response.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
  fs.createReadStream(file).pipe(response);
}).listen(8765,'127.0.0.1',()=>console.log('Plantify preview: http://127.0.0.1:8765'));
