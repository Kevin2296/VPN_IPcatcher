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
  context.updateOverview({engine:'running',version:'2.8.5',vpn_connection:'ovpnc1',ipset_name:'Example',config:{}});
  assert.equal(element('addonVersion').textContent,'2.8.5');
  assert.equal(element('selectedVpn').textContent,'OpenVPN 1');
  context.updateOverview({engine:'running',vpn_connection:'wgc3',config:{}});
  assert.equal(element('selectedVpn').textContent,'WireGuard 3');
  for (const key of Object.keys(context.VPNIPC_I18N.nl)) assert.ok(context.VPNIPC_I18N.en[key], `Missing English key: ${key}`);
}
assert.equal(context.escapeHtml('<script>'), '&lt;script&gt;');
assert.doesNotMatch(element('liveOutput').innerHTML, /<script>/);
console.log('PASS: WebUI JavaScript, NL/EN key parity, waiting-list rendering and HTML escaping');
