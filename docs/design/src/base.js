/* Shared runtime for D2 prototypes. Exposes window.P. */
(function(){
'use strict';
const P=window.P={};
const $=P.$=(s,r)=>(r||document).querySelector(s);
const $$=P.$$=(s,r)=>[...(r||document).querySelectorAll(s)];

/* ---- preferences (shared across the D2 pages) ---- */
const KEY='pagdandi-prefs-v1';
const prefs=P.prefs={sun:0,glove:0,hi:0,left:0,reduce:0,ts:0};
try{Object.assign(prefs,JSON.parse(localStorage.getItem(KEY)||'{}'))}catch(e){}
prefs.hi=0; // English only (decision 2026-10-27)
const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(prefs))}catch(e){}};
P.listeners=[];
P.T=(en,h)=>prefs.hi?h:en;
P.ic=(n,c,st)=>`<svg class="i ${c||''}"${st?` style="${st}"`:''}><use href="#i-${n}"/></svg>`;
P.apply=function(){
  const b=document.body;
  b.classList.toggle('sun',!!prefs.sun); b.classList.toggle('glove',!!prefs.glove);
  b.classList.toggle('hi',!!prefs.hi); b.classList.toggle('left',!!prefs.left);
  b.classList.toggle('reduce',!!prefs.reduce||matchMedia('(prefers-reduced-motion: reduce)').matches);
  b.classList.toggle('ts15',!!prefs.ts);
  $$('.tg[data-p]').forEach(t=>t.setAttribute('aria-pressed',!!prefs[t.dataset.p]));
  const d=$('#dock'); if(d)d.classList.toggle('left',!!prefs.left);
  $$('.t').forEach(e=>{ if(!e.dataset.en)e.dataset.en=e.textContent; e.textContent=prefs.hi?e.dataset.hi:e.dataset.en });
};
$$('.tg[data-p]').forEach(t=>t.addEventListener('click',()=>{
  prefs[t.dataset.p]=prefs[t.dataset.p]?0:1; save(); P.apply(); P.listeners.forEach(f=>f(t.dataset.p)); }));

/* ---- haptic / voice log (a visible stand-in for the phone's vibrator and speaker) ---- */
const hasVib=!!navigator.vibrate;
P.hap=function(txt,pat){
  const el=$('#hlog'); if(el)el.innerHTML='haptic: <b>'+txt+'</b>'+(hasVib?'':' (no vibrator here)');
  if(hasVib&&pat)try{navigator.vibrate(pat)}catch(e){} };
P.say=function(en,hi){ const el=$('#vlog'); if(el)el.innerHTML='voice (after chime): <b>“'+(prefs.hi?hi:en)+'”</b>' };
P.go=url=>{ setTimeout(()=>{location.href=url},450) };

/* ---- helpers ---- */
P.shortest=(cur,target)=>cur+(((target-cur)%360+540)%360-180);
const TAGS=P.TAGS={ok:['ok','On route','रास्ते पर'],junction:['fork','Junction ahead','आगे दोराहा'],off:['warn','Off route','रास्ते से हटे'],
  wrong:['uturn','Wrong way','गलत दिशा'],gps:['gps','GPS lost','GPS सिग्नल नहीं'],regroup:['radar','Regrouping','एकजुट हो रहे हैं'],
  sos:['sos','SOS','SOS'],lost:['stay','Lost mode','खोए हुए'],flost:['radar','Friend out of range','साथी सीमा से बाहर'],
  fsos:['sos','Friend SOS','साथी का SOS'],fall:['warn','Fall detected','गिरना पता चला'],free:['pin','Tracking','ट्रैकिंग']};
P.tag=k=>`<span class="tag" data-s="${k}">${P.ic(TAGS[k][0])}${P.T(TAGS[k][1],TAGS[k][2])}</span>`;
P.mkCtl=function(el,items,fn,first){
  el.innerHTML=items.map((it,i)=>`<button data-s="${it[0]}" aria-pressed="${!!first&&i===0}">${it[1]}</button>`).join('');
  el.addEventListener('click',e=>{ const b=e.target.closest('button'); if(!b)return;
    if(!b.dataset.s.startsWith('_'))$$('button',el).forEach(x=>x.setAttribute('aria-pressed',x===b));
    fn(b.dataset.s,b) });
};

/* ---- HoldButton ---- */
P.holdRound=(label,secs,col,d,aria)=>`<div class="hold" role="button" tabindex="0" aria-label="${aria}" data-secs="${secs}" style="--c:${col};--d:${d}px"><svg class="ring" viewBox="0 0 100 100"><rect class="track" x="4" y="4" width="92" height="92" rx="22" pathLength="100"/><rect class="prog" x="4" y="4" width="92" height="92" rx="22" pathLength="100"/></svg><span class="face">${label}</span></div>`;
P.holdWide=(label,secs,col,aria,icon)=>`<div class="hold wide" role="button" tabindex="0" aria-label="${aria}" data-secs="${secs}" style="--c:${col}"><div class="fill"></div><span class="face">${icon?P.ic(icon):''}<span>${label}</span></span></div>`;
P.wireHold=function(h,onDone){
  const secs=+h.dataset.secs, prog=h.querySelector('.prog'), fill=h.querySelector('.fill'), C=100;
  if(prog){prog.style.strokeDasharray=C;prog.style.strokeDashoffset=C}
  let raf=0,t0=0,last=0,done=false,active=false;
  const set=f=>{ if(prog)prog.style.strokeDashoffset=C*(1-f); if(fill)fill.style.transform=`scaleX(${f})` };
  function step(now){ const f=Math.min(1,(now-t0)/(secs*1000)); set(f); const s=Math.floor((now-t0)/1000);
    if(s>last){last=s;P.hap('tick '+s+' of '+secs,10)}
    if(f>=1){done=true;active=false;h.classList.add('done');P.hap('one strong pulse · hold complete',[0,200]);if(onDone)onDone();return}
    raf=requestAnimationFrame(step) }
  function start(){ if(done||active)return; active=true; h.classList.remove('release'); t0=performance.now(); last=0; P.hap('tap tick 10 ms',10); raf=requestAnimationFrame(step) }
  function stop(){ if(!active)return; active=false; cancelAnimationFrame(raf); h.classList.add('release'); set(0); P.hap('released early · springs back') }
  h.addEventListener('pointerdown',e=>{ h.setPointerCapture(e.pointerId); start() });
  ['pointerup','pointercancel'].forEach(ev=>h.addEventListener(ev,stop));
  h.addEventListener('keydown',e=>{ if((e.key===' '||e.key==='Enter')&&!e.repeat){e.preventDefault();start()} });
  h.addEventListener('keyup',e=>{ if(e.key===' '||e.key==='Enter')stop() });
  h.addEventListener('contextmenu',e=>e.preventDefault());
};

/* ---- LargeToggle ---- */
P.ltogHTML=(k,on)=>{ const n={torch:['Torch strobe','टॉर्च स्ट्रोब'],siren:['Siren','सायरन']}[k];
  return `<div class="ltog" role="button" tabindex="0" aria-pressed="${!!on}" aria-label="${n[0]}" data-k="${k}">${P.ic(k)}<span><span class="lt-n">${P.T(n[0],n[1])}</span><br><span class="lt-s">${on?P.T('On','चालू'):P.T('Off','बंद')}</span></span></div>` };
P.wireLT=function(t,onChange){
  const flip=()=>{ const on=t.getAttribute('aria-pressed')!=='true'; t.setAttribute('aria-pressed',on);
    t.querySelector('.lt-s').textContent=on?P.T('On','चालू'):P.T('Off','बंद'); P.hap('1 short ('+t.dataset.k+(on?' on':' off')+')',30); if(onChange)onChange(t.dataset.k,on) };
  t.addEventListener('click',flip);
  t.addEventListener('keydown',e=>{ if(e.key===' '||e.key==='Enter'){e.preventDefault();flip()} });
};

/* ---- generic button activation (click + Space/Enter) ---- */
P.press=function(el,fn){ el.addEventListener('click',fn); el.addEventListener('keydown',e=>{ if(e.key===' '||e.key==='Enter'){e.preventDefault();fn()} }) };

/* ---- DirectionDial markup ---- */
P.dialHTML=(st,o)=>{ o=o||{}; return `<div class="dial ${o.big?'big':''}" data-s="${st}" ${o.id?`id="${o.id}"`:''}>${P.ic('arrow','arrow','transform:rotate('+(o.ang||0)+'deg)')}${o.big?'<svg class="ticks" viewBox="0 0 112 112" aria-hidden="true">'+ticks()+'</svg>':''}</div>` };
function ticks(){ let t=''; for(let i=0;i<360;i+=30){const m=i%90===0,r1=m?44:48,r2=54,sn=Math.sin(i*Math.PI/180),cs=Math.cos(i*Math.PI/180);
  t+=`<line x1="${56+sn*r2}" y1="${56-cs*r2}" x2="${56+sn*r1}" y2="${56-cs*r1}" stroke="currentColor" stroke-width="${m?2:1}" opacity="${m?.9:.4}"/>`} return t }

document.addEventListener('DOMContentLoaded',()=>{ P.apply(); });
})();
