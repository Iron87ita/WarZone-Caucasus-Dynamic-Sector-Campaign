const $ = (id) => document.getElementById(id);
let currentState = null;
let selectedSectorId = null;
let selectedTaskId = null;
let taskFilter = 'ALL';

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt = (n) => new Intl.NumberFormat('en-US').format(Number(n || 0));
const ownerLabel = (o) => o === 'blue' ? 'NATO' : o === 'red' ? 'RED' : 'NEUTRAL';
const taskStatus = (s) => String(s || 'UNKNOWN').toUpperCase();

function sectorClass(s){
  return ['sector', s.owner || 'neutral', s.frontline ? 'frontline' : '', s.status === 'destroyed' ? 'destroyed' : '', s.status === 'locked' ? 'locked' : ''].filter(Boolean).join(' ');
}

function selectSector(id){
  selectedSectorId = Number(id);
  document.querySelectorAll('.sector').forEach(el => el.classList.toggle('selected', Number(el.dataset.id) === selectedSectorId));
  renderSectorDetail();
}

function renderSectorDetail(){
  if(!currentState) return;
  let s = (currentState.sectors || []).find(x => Number(x.id) === Number(selectedSectorId));
  if(!s && currentState.activeSector != null) s = (currentState.sectors || []).find(x => Number(x.id) === Number(currentState.activeSector));
  if(!s) return;
  selectedSectorId = Number(s.id);
  $('detailName').textContent = `${s.name || `Sector ${s.id}`} · S${s.id}`;
  $('detailOwner').textContent = ownerLabel(s.owner);
  $('detailStatus').textContent = String(s.status || 'unknown').toUpperCase();
  $('detailLevel').textContent = s.level ?? '—';
  $('detailIncome').textContent = s.income != null ? fmt(s.income) : '—';
}

function pointForSector(s, bounds, index){
  const c = s.geometry?.center;
  if(c && Number.isFinite(c.lat) && Number.isFinite(c.lon) && bounds){
    const x = 55 + ((c.lon - bounds.minLon) / Math.max(0.000001, bounds.maxLon - bounds.minLon)) * 890;
    const y = 565 - ((c.lat - bounds.minLat) / Math.max(0.000001, bounds.maxLat - bounds.minLat)) * 510;
    return {x, y};
  }
  const cols = 5;
  return {x: 120 + (index % cols) * 185, y: 110 + Math.floor(index / cols) * 165};
}

function renderMap(state){
  const svg = $('operationalMap');
  const sectors = state.sectors || [];
  if(!sectors.length){ svg.innerHTML = '<text x="500" y="310" text-anchor="middle" class="map-empty">Waiting for WarZone sector telemetry…</text>'; return; }

  const geo = sectors.map(s => s.geometry?.center).filter(c => c && Number.isFinite(c.lat) && Number.isFinite(c.lon));
  const bounds = geo.length ? {
    minLat: Math.min(...geo.map(c=>c.lat)), maxLat: Math.max(...geo.map(c=>c.lat)),
    minLon: Math.min(...geo.map(c=>c.lon)), maxLon: Math.max(...geo.map(c=>c.lon))
  } : null;
  const positions = new Map();
  sectors.forEach((s,i) => positions.set(Number(s.id), pointForSector(s,bounds,i)));

  const lines = (state.connections || []).map(c => {
    const a = positions.get(Number(c.from)), b = positions.get(Number(c.to));
    if(!a || !b) return '';
    return `<line class="map-link" x1="${a.x.toFixed(1)}" y1="${a.y.toFixed(1)}" x2="${b.x.toFixed(1)}" y2="${b.y.toFixed(1)}" />`;
  }).join('');

  const nodes = sectors.map(s => {
    const p = positions.get(Number(s.id));
    const cls = `map-node ${s.owner || 'neutral'} ${s.frontline ? 'frontline' : ''} ${s.status === 'destroyed' ? 'destroyed' : ''}`;
    const label = esc((s.name || `Sector ${s.id}`).replace(/^sector\s*\d+\s*[|–—:-]?\s*/i,''));
    return `<g class="${cls}" data-sector="${esc(s.id)}" transform="translate(${p.x.toFixed(1)} ${p.y.toFixed(1)})">
      <circle r="${s.frontline ? 25 : 20}"></circle>
      <text class="node-id" y="5" text-anchor="middle">${esc(s.id)}</text>
      <text class="node-name" y="42" text-anchor="middle">${label.slice(0,24)}</text>
    </g>`;
  }).join('');
  svg.innerHTML = `<g class="map-grid">${Array.from({length:9},(_,i)=>`<line x1="${100+i*100}" y1="35" x2="${100+i*100}" y2="585"/>`).join('')}${Array.from({length:6},(_,i)=>`<line x1="35" y1="${85+i*90}" x2="965" y2="${85+i*90}"/>`).join('')}</g>${lines}${nodes}`;
  svg.querySelectorAll('[data-sector]').forEach(el => el.addEventListener('click', () => selectSector(el.dataset.sector)));
  $('mapMeta').textContent = bounds ? `${sectors.length} live sectors · geographic projection` : `${sectors.length} live sectors · topology projection`;
}

function renderPilotSelect(state){
  const select = $('pilotSelect');
  const previous = select.value;
  const players = state.players || [];
  select.innerHTML = '<option value="">Select online pilot…</option>' + players.map(p => `<option value="${esc(p.name)}">${esc(p.name)} · ${esc(ownerLabel(p.side))} · ${esc(p.aircraft || '')}</option>`).join('');
  if(players.some(p => p.name === previous)) select.value = previous;
}

function taskCard(task){
  const status = taskStatus(task.status);
  const accepted = task.acceptedBy ? `<small>Assigned: ${esc(task.acceptedBy)}</small>` : '<small>Click for briefing</small>';
  return `<button class="task-card ${esc(status.toLowerCase())} ${esc(task.coalition || 'neutral')}" data-task-id="${esc(task.id)}">
    <div class="task-card-top"><span class="task-type">${esc(task.type || 'MISSION')}</span><span class="task-state">${esc(status)}</span></div>
    <strong>${esc(task.title || `Task ${task.id}`)}</strong>
    <p>${esc(task.objective || '')}</p>
    <div class="task-card-foot"><span>#${esc(task.id)} · S${esc(task.sector ?? '?')} · ${fmt(task.reward)} CR</span>${accepted}</div>
  </button>`;
}

function renderTasks(state){
  const all = state.tasks || [];
  const filtered = taskFilter === 'ALL' ? all : all.filter(t => String(t.type || '').toUpperCase() === taskFilter);
  $('taskGrid').innerHTML = filtered.length ? filtered.map(taskCard).join('') : '<div class="task-empty">No tasks available from DCS telemetry.</div>';
  $('taskGrid').querySelectorAll('[data-task-id]').forEach(el => el.addEventListener('click', () => openTaskBriefing(Number(el.dataset.taskId))));

  if(selectedTaskId != null && $('taskDialog').open) renderTaskBriefing(selectedTaskId);
}

function chipList(values){
  return (values || []).length ? values.map(v => `<span class="brief-chip">${esc(v)}</span>`).join('') : '<span class="brief-chip muted">None reported</span>';
}

function renderTaskBriefing(id){
  if(!currentState) return;
  const task = (currentState.tasks || []).find(t => Number(t.id) === Number(id));
  if(!task) return;
  selectedTaskId = Number(task.id);
  const status = taskStatus(task.status);
  $('briefType').textContent = task.type || 'MISSION';
  $('briefTitle').textContent = task.title || `Task ${task.id}`;
  $('briefMeta').textContent = `TASK ID #${task.id}${task.activationId ? ` · LOGIC ${task.activationId}` : ''}`;
  $('briefStatus').textContent = status;
  $('briefSector').textContent = task.sector != null ? `SECTOR ${task.sector}` : '—';
  $('briefReward').textContent = `${fmt(task.reward)} CR`;
  $('briefCoalition').textContent = ownerLabel(task.coalition);
  $('briefObjective').textContent = task.objective || '—';
  $('briefText').textContent = task.briefing || 'No briefing available.';
  $('briefThreats').innerHTML = chipList(task.threats);
  $('briefAircraft').innerHTML = chipList(task.recommendedAircraft);

  const pilot = $('pilotSelect').value;
  const canAccept = status === 'AVAILABLE' && !!pilot && String(currentState.status || '').toUpperCase() === 'ONLINE';
  $('acceptTaskButton').disabled = !canAccept;
  if(status !== 'AVAILABLE') $('briefPilotHint').textContent = task.acceptedBy ? `${status} · assigned to ${task.acceptedBy}` : `Task status: ${status}`;
  else if(!pilot) $('briefPilotHint').textContent = 'Select your online DCS pilot before accepting.';
  else $('briefPilotHint').textContent = `Accept as ${pilot}. DCS will validate that the pilot is online on the correct coalition.`;
}

function openTaskBriefing(id){
  renderTaskBriefing(id);
  const dialog = $('taskDialog');
  if(!dialog.open) dialog.showModal();
}

async function acceptSelectedTask(){
  if(selectedTaskId == null) return;
  const playerName = $('pilotSelect').value;
  if(!playerName) return;
  const button = $('acceptTaskButton');
  button.disabled = true;
  button.textContent = 'SENDING TO DCS…';
  $('taskMessage').textContent = '';
  try{
    const r = await fetch(`/api/tasks/${selectedTaskId}/accept`, {
      method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({playerName})
    });
    const data = await r.json();
    if(!r.ok) throw new Error(data.error || `HTTP ${r.status}`);
    $('taskMessage').textContent = `Task #${selectedTaskId} queued for DCS. Waiting for mission confirmation…`;
    $('taskDialog').close();
  }catch(error){
    $('briefPilotHint').textContent = `Unable to accept: ${error.message}`;
    button.disabled = false;
  }finally{
    button.textContent = 'ACCEPT MISSION';
  }
}

function render(state){
  currentState = state;
  $('serverStatus').textContent = state.status || 'UNKNOWN';
  $('statusDot').className = `dot ${(state.status||'').toLowerCase()==='online'?'online':'offline'}`;
  $('updatedAt').textContent = state.updatedAt ? `updated ${new Date(state.updatedAt).toLocaleTimeString()}` : 'live file telemetry';
  $('activeSector').textContent = state.activeSector != null ? `SECTOR ${state.activeSector}` : 'MULTI-FRONT';
  $('players').textContent = `${state.playersOnline ?? 0} / ${state.maxPlayers ?? 0}`;
  $('missionTime').textContent = state.missionTime || '—';
  $('version').textContent = state.version ? `v${state.version}` : '—';

  const sectors = state.sectors || [];
  const blue = sectors.filter(s=>s.owner==='blue').length;
  const red = sectors.filter(s=>s.owner==='red').length;
  const neutral = sectors.filter(s=>s.owner!=='blue' && s.owner!=='red').length;
  const fronts = sectors.filter(s=>s.frontline).length;
  $('sectorCount').textContent = `${sectors.length} sectors`;
  $('blueControl').textContent = blue; $('redControl').textContent = red; $('neutralControl').textContent = neutral; $('frontCount').textContent = fronts;
  $('blueCredits').textContent = fmt(state.coalitions?.blue?.credits);
  $('redCredits').textContent = fmt(state.coalitions?.red?.credits);
  const walletTotal = state.coalitions?.blue?.walletTotal ?? state.playerWallets?.total;
  const walletCount = state.coalitions?.blue?.walletCount ?? state.playerWallets?.count;
  $('blueWallets').textContent = walletTotal != null ? `${fmt(walletTotal)} in ${walletCount || 0} player wallets` : '';

  $('sectorGrid').innerHTML = sectors.map(s=>`<button class="${sectorClass(s)}" data-id="${esc(s.id)}"><strong>${esc(s.id)}</strong><span>${esc(s.name || `Sector ${s.id}`)}</span><small>${esc(ownerLabel(s.owner))}${s.frontline?' · FRONT':''}${s.status==='locked'?' · LOCKED':''}</small></button>`).join('');
  document.querySelectorAll('.sector').forEach(el => el.addEventListener('click',()=>selectSector(el.dataset.id)));

  $('operations').innerHTML = (state.operations||[]).map(o=>`<div class="row"><span class="tag ${esc(o.side||'')}">${esc(o.type||'OP')}</span><strong>${esc(o.title||o.id||'Operation')}</strong><small>${esc(o.status||'')} · S${esc(o.sector ?? '?')}</small></div>`).join('') || '<div class="row empty"><small>No active WarZone operations</small></div>';
  $('events').innerHTML = (state.events||[]).map(e=>`<div class="row event ${esc(e.side||'neutral')}"><span class="tag">${esc(e.time||'--:--')}</span><strong>${esc(e.text||'')}</strong></div>`).join('') || '<div class="row empty"><small>No campaign changes since telemetry started</small></div>';
  $('pilotList').innerHTML = (state.players||[]).map(p=>`<div class="row pilot"><span class="tag ${esc(p.side||'')}">${esc(ownerLabel(p.side))}</span><strong>${esc(p.name||'Pilot')}</strong><small>${esc(p.aircraft||'')}</small></div>`).join('') || '<div class="row empty"><small>No players online</small></div>';

  renderPilotSelect(state);
  renderTasks(state);
  renderMap(state);
  if(selectedSectorId == null && state.activeSector != null) selectedSectorId = Number(state.activeSector);
  renderSectorDetail();

  if($('taskMessage').textContent && (state.tasks || []).some(t => Number(t.id) === Number(selectedTaskId) && taskStatus(t.status) === 'ACTIVE')) {
    $('taskMessage').textContent = `Task #${selectedTaskId} confirmed ACTIVE by DCS.`;
  }
}

$('taskFilters').querySelectorAll('[data-filter]').forEach(button => button.addEventListener('click', () => {
  taskFilter = button.dataset.filter;
  $('taskFilters').querySelectorAll('[data-filter]').forEach(b => b.classList.toggle('active', b === button));
  if(currentState) renderTasks(currentState);
}));
$('pilotSelect').addEventListener('change', () => { if(selectedTaskId != null && $('taskDialog').open) renderTaskBriefing(selectedTaskId); });
$('acceptTaskButton').addEventListener('click', acceptSelectedTask);

async function initial(){
  try{ const r=await fetch('/api/state',{cache:'no-store'}); render(await r.json()); }
  catch(e){ console.error(e); }
}
initial();

const stream = new EventSource('/events');
stream.onmessage = (ev) => { try{ render(JSON.parse(ev.data)); } catch(e){ console.error(e); } };
stream.onerror = () => { $('serverStatus').textContent='DISCONNECTED'; $('statusDot').className='dot offline'; };
