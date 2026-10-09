const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../addons/vpn_ipcatcher.d/vpn_ipcatcher.asp'), 'utf8');
const scripts = [...source.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)]
  .map(match => match[1].replace(/<%[\s\S]*?%>/g, '{}')).filter(Boolean);
const elements = new Map();
const element = id => {
  if (!elements.has(id)) elements.set(id, { innerHTML: '', textContent: '', value: '', classList: { add() {}, remove() {} } });
  return elements.get(id);
};
const context = vm.createContext({
  window: { addEventListener() {} },
  document: { getElementById: element, querySelectorAll: () => [] },
  console,
  setTimeout,
  clearTimeout,
  TextEncoder,
  fetch: () => { throw new Error('Unexpected network request'); }
});
for (const script of scripts) new vm.Script(script).runInContext(context);
for (const language of ['nl', 'en']) {
  context.vpnipcCurrentLanguage = language;
  context.dataCache = { waiting_text: 'Name: example_wait\nMembers:\n203.0.113.10 timeout 60 packets 0 bytes 0 comment "src=test;seen=20261007-120000"' };
  context.setTab('waiting');
  assert.match(element('liveOutput').innerHTML, /203\.0\.113\.10/);
  assert.equal(context.t('waiting'), language === 'nl' ? 'Wachtlijst' : 'Waiting');
  context.updateOverview({engine:'running',version:'2.8.9',vpn_connection:'ovpnc1',ipset_name:'Example',config:{}});
  assert.equal(element('addonVersion').textContent,'2.8.9');
  assert.equal(element('selectedVpn').textContent,'OpenVPN 1');
  context.updateOverview({engine:'running',vpn_connection:'wgc3',config:{}});
  assert.equal(element('selectedVpn').textContent,'WireGuard 3');
  for (const key of Object.keys(context.VPNIPC_I18N.nl)) assert.ok(context.VPNIPC_I18N.en[key], `Missing English key: ${key}`);
}
assert.equal(context.escapeHtml('<script>'), '&lt;script&gt;');
assert.doesNotMatch(element('liveOutput').innerHTML, /<script>/);
console.log('PASS: WebUI JavaScript, NL/EN key parity, waiting-list rendering and HTML escaping');
context.currentTab='flows';
const flows=context.parseFlows('Bytes Source Destination Port Cand Final Hint\n0004000000 192.0.2.10 203.0.113.1 443 no yes watch\n0001000000 192.0.2.11 203.0.113.2 80 yes no watch\n0002000000 192.0.2.10 203.0.113.3 443 no no excluded-range');
assert.equal(context.filterLiveRows(flows).length,3);
element('flowSource').value='192.0.2.10';
element('flowPort').value='443';
element('flowState').value='excluded';
assert.equal(context.filterLiveRows(flows).length,1);
element('liveSearch').value='203.0.113.1';
assert.equal(context.filterLiveRows(flows).length,0);
element('flowState').value='final';
assert.equal(context.filterLiveRows(flows).length,1);
context.currentTab='log';
element('liveSearch').value='error';
assert.equal(context.filterLiveRows([{msg:'ERROR example'},{msg:'OK'}]).length,1);
assert.equal(context.formatFlowBytes('0004000000'),'4 MB');
assert.equal(context.formatFlowBytes('0'),'0 B');
console.log('PASS: combined source/port/state/search filters, text views and readable byte counts');
const devices=context.diagnosticDevices({maclist:['a','b','c'],a:{isOnline:'1',ip:'192.0.2.10',nickName:'Example TV'},b:{isOnline:'0',ip:'192.0.2.11',name:'Offline'},c:{isOnline:'1',ip:'192.0.2.10',name:'Duplicate'}});
assert.equal(devices.length,1);
assert.equal(devices[0].name,'Example TV');
assert.equal(context.diagnosticDevices({x:{isOnline:'1',ip:'999.0.2.10'}}).length,0);
console.log('PASS: ASUS online IPv4 devices, deduplication and invalid-address rejection');
