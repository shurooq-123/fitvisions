// Controlled local bridge comparison. No Cloudflare credential is read or logged.
// Usage: node tools/compare-avatar-models.mjs <fixture.json> <output-directory>
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve,join} from 'node:path';
import {createHash} from 'node:crypto';
const fixture=JSON.parse(await readFile(process.argv[2],'utf8'));
const out=resolve(process.argv[3]??'output/avatar-model-comparison');
await mkdir(out,{recursive:true});
const config=JSON.parse(await readFile('build/ai-local-config.json','utf8'));
if(config.FITVISIONS_AI_URL!=='http://127.0.0.1:8787')throw new Error('Only the local bridge is supported');
const records=[];
const fingerprint=createHash('sha256').update(JSON.stringify(fixture)).digest('hex');
for(const model of ['flux-2-klein-4b','flux-2-klein-9b']){
  const start=Date.now();
  try{
    const response=await fetch(config.FITVISIONS_AI_URL+'/generate',{method:'POST',headers:{'content-type':'application/json','x-fitvisions-session':config.FITVISIONS_AI_SESSION},body:JSON.stringify({...fixture,model,seed:42}),signal:AbortSignal.timeout(195000)});
    const data=await response.json();
    if(!response.ok)throw new Error(data.error??'Bridge request failed');
    if(data.model!==model)throw new Error('Model provenance not confirmed. Restart bridge.');
    const bytes=Buffer.from(data.image.replace(/^data:image\/[^;]+;base64,/,''),'base64');
    const extension=bytes[0]===137?'png':bytes[0]===255?'jpg':'webp';
    const file=model+'.'+extension;
    await writeFile(join(out,file),bytes);
    records.push({model,status:'generated',seconds:(Date.now()-start)/1000,image:file,inputSha256:fingerprint,seed:42});
  }catch(e){records.push({model,status:'failed',error:e.message,inputSha256:fingerprint,seed:42});}
  await writeFile(join(out,'report.json'),JSON.stringify({case:fixture.case??'same-input-comparison',records,scope:'Visual comparison only. No centimetre accuracy or winner inferred from images.'},null,2));
  console.log(model+': '+records.at(-1).status);
}
