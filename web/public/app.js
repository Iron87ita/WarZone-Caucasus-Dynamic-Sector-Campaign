const $ = (id) => document.getElementById(id);

function fmt(n){return new Intl.NumberFormat('en-US').format(Number(n||0));}
function sectorClass(s){return ['sector',s.status==='active'?'active':'',s.owner==='blue'?'blue':'',s.owner==='red'?'red':''].filter(Boolean).join(' ')}

function render(state){
  $('serverStatus').textContent = state.status || 'UNKNOWN';
  $('statusDot').className = `dot ${(state.status||'').toLowerCase()==='online'?'online':'offline'}`;
  $('updatedAt').textContent = state.updatedAt ? `updated ${new Date(state.updatedAt).toLocaleTimeString()}` : 'no telemetry';
  $('activeSector').textContent = state.activeSector ? `SECTOR ${state.activeSector}` : '—';
  $('players').textContent = `${state.playersOnline ?? 0} / ${state.maxPlayers ?? 0}`;
  $('missionTime').textContent = state.missionTime || '—';
  $('version').textContent = state.version ? `v${state.version}` : '—';

  const active=(state.sectors||[]).find(s=>s.id===state.activeSector) || {};
  $('sectorLabel').textContent = active.name || 'Current front';
  const bp=Number(active.blueProgress||0), rp=Number(active.redProgress||0);
  $('blueProgress').textContent=`${bp}%`; $('redProgress').textContent=`${rp}%`;
  $('blueBar').style.width=`${bp}%`; $('redBar').style.width=`${rp}%`;
  $('blueCredits').textContent=fmt(state.coalitions?.blue?.credits);
  $('redCredits').textContent=fmt(state.coalitions?.red?.credits);

  $('sectorGrid').innerHTML=(state.sectors||[]).map(s=>`<div class="${sectorClass(s)}"><strong>${s.id}</strong><small>${s.status||s.owner||'unknown'}</small></div>`).join('');
  $('operations').innerHTML=(state.operations||[]).map(o=>`<div class="row"><span class="tag">${o.id||o.type||'OP'}</span><strong>${o.title||o.type||'Operation'}</strong><small>S${o.sector||'?'} · ${o.status||''}</small></div>`).join('') || '<div class="row"><small>No active operations</small></div>';
  $('events').innerHTML=(state.events||[]).map(e=>`<div class="row event ${e.side||'neutral'}"><span class="tag">${e.time||'--:--'}</span><strong>${e.text||''}</strong></div>`).join('') || '<div class="row"><small>No recent events</small></div>';
}

async function initial(){
  try{ const r=await fetch('/api/state',{cache:'no-store'}); render(await r.json()); }
  catch(e){ console.error(e); }
}
initial();

const stream=new EventSource('/events');
stream.onmessage=(ev)=>{ try{ render(JSON.parse(ev.data)); }catch(e){console.error(e)} };
stream.onerror=()=>{ $('serverStatus').textContent='DISCONNECTED'; $('statusDot').className='dot offline'; };
