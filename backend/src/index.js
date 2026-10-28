import {createRemoteJWKSet, jwtVerify} from 'jose';
const jwks = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
const json = (data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'content-type':'application/json','cache-control':'no-store'}});
const cents = (v)=>Number.isSafeInteger(v)&&v>=0;
const cryptoHex = bytes=>[...new Uint8Array(bytes)].map(x=>x.toString(16).padStart(2,'0')).join('');
async function auth(req,env){
 const token=req.headers.get('authorization')?.match(/^Bearer (.+)$/i)?.[1];
 if(!token) throw new Error('Authentication required');
 const {payload}=await jwtVerify(token,jwks,{issuer:`https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,audience:env.FIREBASE_PROJECT_ID,algorithms:['RS256']});
 return {uid:payload.sub,admin:env.ADMIN_UIDS.split(',').map(s=>s.trim()).includes(payload.sub)};
}
async function signature(secret,data){const k=await crypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);return cryptoHex(await crypto.subtle.sign('HMAC',k,new TextEncoder().encode(data)));}
function safeOrder(o){return {id:o.id,order_id:o.id,fileName:o.file_name,file_name:o.file_name,customerName:o.customer_name,customerPhone:o.customer_phone,customerEmail:o.customer_email,pageCount:o.page_count,copies:o.copies,isColorPrint:!!o.is_color_print,isDoubleSided:!!o.is_double_sided,paperSize:o.paper_size,bindingType:o.binding_type,deliveryAddress:o.delivery_address,courierCharge:o.courier_charge_paise/100,totalAmount:o.amount_paise/100,status:o.status,paymentStatus:o.payment_status,created_at:o.created_at};}
export default {async fetch(req,env){
 try{
  const u=new URL(req.url),p=u.pathname,method=req.method;
  if(p==='/health')return json({ok:true,service:'rohini-xerox-api'});
  const user=await auth(req,env);
  if(p==='/upload'&&method==='POST'){
   const form=await req.formData(),file=form.get('file');
   if(!(file instanceof File)||file.type!=='application/pdf'||file.size>15*1024*1024||file.size===0)return json({error:'PDF required (max 15 MB)'},400);
   const key=`${user.uid}/${crypto.randomUUID()}.pdf`;
   await env.DOCUMENTS.put(key,file.stream(),{httpMetadata:{contentType:'application/pdf'}});
   return json({storageKey:key,fileName:file.name});
  }
  if(p==='/orders'&&method==='POST'){
   const d=await req.json(),id=crypto.randomUUID(),copies=Number(d.copies),pages=Number(d.pageCount);
   if(!Number.isSafeInteger(copies)||copies<1||copies>100||!Number.isSafeInteger(pages)||pages<1||pages>2000)return json({error:'Invalid pages or copies'},400);
   if(typeof d.storageKey!=='string'||!d.storageKey.startsWith(user.uid+'/')||!await env.DOCUMENTS.head(d.storageKey))return json({error:'Upload a PDF first'},400);
   const color=!!d.isColorPrint,duplex=!!d.isDoubleSided,delivery=String(d.deliveryAddress||'').trim();
   if(delivery.length>500)return json({error:'Delivery address too long'},400);
   const courier=delivery?6000:0,amount=pages*copies*(color?1000:200)+courier;
   await env.DB.prepare(`INSERT INTO orders(id,user_id,customer_name,customer_email,customer_phone,file_name,storage_key,page_count,copies,is_color_print,is_double_sided,paper_size,binding_type,delivery_address,courier_charge_paise,amount_paise) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).bind(id,user.uid,String(d.customerName||'').slice(0,120),String(d.customerEmail||'').slice(0,180),String(d.customerPhone||'').slice(0,30),String(d.fileName||'document.pdf').slice(0,200),d.storageKey,pages,copies,+color,+duplex,'A4','none',delivery||null,courier,amount).run();
   return json({id,orderId:id,totalAmount:amount/100,status:'pending_payment'},201);
  }
  if(p==='/orders'&&method==='GET'){
   const r=user.admin?await env.DB.prepare('SELECT * FROM orders ORDER BY created_at DESC LIMIT 100').all():await env.DB.prepare('SELECT * FROM orders WHERE user_id=? ORDER BY created_at DESC LIMIT 100').bind(user.uid).all();
   return json(r.results.map(safeOrder));
  }
  const m=p.match(/^\/orders\/([^/]+)(?:\/(payment-order|verify-payment|status|document))?$/);
  if(m){
   const id=m[1],action=m[2],o=await env.DB.prepare('SELECT * FROM orders WHERE id=?').bind(id).first();
   if(!o)return json({error:'Not found'},404);
   if(o.user_id!==user.uid&&!user.admin)return json({error:'Forbidden'},403);
   if(!action&&method==='GET')return json(safeOrder(o));
   if(action==='document'&&method==='GET'){
    const obj=await env.DOCUMENTS.get(o.storage_key);if(!obj)return json({error:'File not found'},404);
    return new Response(obj.body,{headers:{'content-type':'application/pdf','content-disposition':'attachment; filename="document.pdf"','cache-control':'no-store'}});
   }
   if(action==='payment-order'&&method==='POST'){
    if(o.payment_status==='paid')return json({error:'Already paid'},409);
    if(!env.RAZORPAY_KEY_SECRET||!env.RAZORPAY_KEY_ID)return json({error:'Payment provider not configured'},503);
    const basic=btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
    const resp=await fetch('https://api.razorpay.com/v1/orders',{method:'POST',headers:{authorization:`Basic ${basic}`,'content-type':'application/json'},body:JSON.stringify({amount:o.amount_paise,currency:'INR',receipt:id.slice(0,40)})});
    if(!resp.ok)return json({error:'Unable to create payment order'},502);
    const payment=await resp.json();
    await env.DB.prepare('UPDATE orders SET razorpay_order_id=? WHERE id=?').bind(payment.id,id).run();
    return json({key:env.RAZORPAY_KEY_ID,razorpayOrderId:payment.id,amount:o.amount_paise,currency:'INR'});
   }
   if(action==='verify-payment'&&method==='POST'){
    const d=await req.json();
    if(!o.razorpay_order_id||d.razorpay_order_id!==o.razorpay_order_id||typeof d.razorpay_payment_id!=='string'||typeof d.razorpay_signature!=='string')return json({error:'Invalid payment details'},400);
    const expected=await signature(env.RAZORPAY_KEY_SECRET,`${o.razorpay_order_id}|${d.razorpay_payment_id}`);
    let mismatch=expected.length^d.razorpay_signature.length;for(let i=0;i<Math.max(expected.length,d.razorpay_signature.length);i++)mismatch|=(expected.charCodeAt(i)||0)^(d.razorpay_signature.charCodeAt(i)||0);
    if(mismatch)return json({error:'Invalid payment signature'},400);
    const basic=btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
    const r=await fetch(`https://api.razorpay.com/v1/payments/${encodeURIComponent(d.razorpay_payment_id)}`,{headers:{authorization:`Basic ${basic}`}});
    if(!r.ok)return json({error:'Payment lookup failed'},502);
    const payment=await r.json();
    if(payment.order_id!==o.razorpay_order_id||payment.amount!==o.amount_paise||payment.currency!=='INR'||!['authorized','captured'].includes(payment.status))return json({error:'Payment not confirmed'},409);
    await env.DB.prepare("UPDATE orders SET payment_status='paid',status='pending',razorpay_payment_id=? WHERE id=? AND payment_status!='paid'").bind(payment.id,id).run();
    return json({verified:true,paymentStatus:'paid'});
   }
   if(action==='status'&&method==='PUT'){
    if(!user.admin)return json({error:'Admin only'},403);
    const d=await req.json(),allowed=['pending','processing','ready','out_for_delivery','delivered','completed','cancelled'];
    if(!allowed.includes(d.status))return json({error:'Invalid status'},400);
    await env.DB.prepare('UPDATE orders SET status=? WHERE id=?').bind(d.status,id).run();return json({ok:true,status:d.status});
   }
  }
  return json({error:'Route not found'},404);
 }catch(e){if(['Authentication required','JWTExpired','JWTInvalid'].includes(e.message)||e.code?.startsWith('ERR_JWT'))return json({error:'Unauthorized'},401);return json({error:'Request failed',detail:env.DEBUG==='true'?String(e):undefined},500);}
}};
