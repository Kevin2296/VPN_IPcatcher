<!DOCTYPE html>
<html>
<head>
<title>VPN IP Catcher - ASUS Merlin</title>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta name="viewport" content="width=device-width, initial-scale=1">

<link rel="stylesheet" type="text/css" href="/index_style.css">
<link rel="stylesheet" type="text/css" href="/form_style.css">
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/js/httpApi.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/validator.js"></script>

<style>
/* JOUW EIGEN CSS - body aangepast naar .vpn_ipcatcher_dashboard */
.vpn_ipcatcher_dashboard{font-family:Arial,Helvetica,sans-serif;background:#1f2d3a;color:#d9e6f2;margin:0;padding:0; border-radius:10px; overflow:hidden;}
.wrap{max-width:1280px;margin:0 auto;padding:18px}
.topbar{background:linear-gradient(135deg,#26394c,#182430);border:1px solid #34495e;border-radius:12px;padding:18px 20px;margin-bottom:14px;box-shadow:0 8px 24px rgba(0,0,0,.25)}
.title{font-size:28px;font-weight:700;color:#fff}
.subtitle{color:#a9bdcf;margin-top:5px;font-size:13px}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:14px 0}
.card{background:#233446;border:1px solid #3a536b;border-radius:12px;padding:14px;box-shadow:0 6px 18px rgba(0,0,0,.18)}
.card h3{margin:0 0 8px;color:#9cc9ff;font-size:13px;text-transform:uppercase;letter-spacing:.8px}
.big{font-size:24px;color:#fff;font-weight:700}
.muted{color:#a9bdcf;font-size:12px}
.badge{display:inline-block;padding:4px 10px;border-radius:999px;font-size:12px;font-weight:700}
.ok{background:#1d6b44;color:#d5ffe9}.bad{background:#762b2b;color:#ffe0e0}.warn{background:#80621d;color:#fff0c5}
.panel{background:#223243;border:1px solid #3a536b;border-radius:12px;margin:14px 0;overflow:hidden}
.panel-title{background:#192838;color:#fff;padding:12px 14px;font-weight:700;border-bottom:1px solid #3a536b}
.panel-body{padding:14px}
.actions{display:flex;gap:8px;flex-wrap:wrap}
.btn{border:1px solid #4e6c86;background:#2d465d;color:#fff;border-radius:8px;padding:9px 13px;cursor:pointer;font-weight:700}
.btn:hover{background:#3c5e7b}.btn.green{background:#1e7048}.btn.red{background:#7a3030}.btn.orange{background:#8a5a1c}.btn.blue{background:#235f8f}.btn:disabled{opacity:.5;cursor:wait}
.vpn_ipcatcher_dashboard .layoutTabs,.vpn_ipcatcher_dashboard .tabs{display:flex;gap:10px;flex-wrap:wrap}
.vpn_ipcatcher_dashboard .layoutTabs{margin:12px 0 2px}
.vpn_ipcatcher_dashboard .layoutTab,.vpn_ipcatcher_dashboard .tab{padding:10px 16px;border-radius:12px;border:1px solid #4b6780;background:#182532;color:#dce9f6;cursor:pointer;font-size:15px;font-weight:700}
.vpn_ipcatcher_dashboard .layoutTab.active,.vpn_ipcatcher_dashboard .tab.active{background:#3a6f9e;color:#fff;border-color:#5f8eb7}
.page{display:none}.page.active{display:block}
.split{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.formgrid{display:grid;grid-template-columns:220px 1fr;gap:10px 14px;align-items:center}
.formgrid label{color:#c4d5e6}
.formgrid input,.formgrid select,.formgrid textarea{background:#101923;color:#fff;border:1px solid #4a657d;border-radius:8px;padding:8px;width:100%;box-sizing:border-box}
.formgrid textarea{min-height:96px;font-family:monospace}
.note{background:#162435;border-left:4px solid #4e9ee8;padding:10px 12px;border-radius:8px;color:#cfe2f4;margin-bottom:12px}
.footer{color:#8fa7bb;font-size:12px;margin:12px 0;text-align:right}
pre{white-space:pre-wrap;word-break:break-word;background:#101923;border:1px solid #31475c;border-radius:10px;padding:12px;color:#dcecff;max-height:440px;overflow:auto;font-size:12px;line-height:1.35}
table.data{width:100%;border-collapse:collapse;background:#101923;border:1px solid #31475c;border-radius:10px;overflow:hidden;font-size:13px}
table.data th,table.data td{padding:8px 10px;border-bottom:1px solid #243849;vertical-align:top;text-align:left}
table.data th{background:#152434;color:#bcd7ef;font-size:12px;text-transform:uppercase;letter-spacing:.5px}
table.data tr:last-child td{border-bottom:none}
.scroll{max-height:460px;overflow:auto;border-radius:10px}
.mono{font-family:Consolas,Monaco,monospace}
.presetGrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.presetCard{background:#182634;border:1px solid #35506a;border-radius:12px;padding:12px}
.presetCard h4{margin:0 0 8px;color:#9cc9ff}
.presetItem{display:flex;gap:10px;align-items:flex-start;padding:10px 0;border-top:1px solid #274052}
.presetItem:first-child{border-top:none}
.presetMeta{font-size:12px;color:#9eb4c8;margin-top:3px;line-height:1.35}
.pill{display:inline-block;padding:2px 8px;border-radius:999px;background:#28445a;color:#d7ebff;font-size:11px;margin-right:6px}
.search{margin-bottom:12px}
.search input{background:#101923;color:#fff;border:1px solid #4a657d;border-radius:10px;padding:10px 12px;width:100%;box-sizing:border-box}
.helperBar{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}
.statusOn{color:#7df2ab;font-weight:700}
.statusPart{color:#ffd37f;font-weight:700}
.statusOff{color:#9eb4c8;font-weight:700}
.smallinfo{font-size:12px;color:#a9bdcf}
@media(max-width:980px){.grid{grid-template-columns:repeat(2,1fr)}.split,.presetGrid{grid-template-columns:1fr}.formgrid{grid-template-columns:1fr}.wrap{padding:10px}}
/* ASUS_COMPACT_START */

.vpn_ipcatcher_dashboard {
  width: 100%;
  background: #475a5f;
  color: #ffffff;
  border-radius: 0;
  overflow: visible;
}

.vpn_ipcatcher_dashboard * {
  box-sizing: border-box;
}

.vpn_ipcatcher_dashboard .wrap {
  max-width: none;
  width: 100%;
  margin: 0;
  padding: 12px;
}

/* Compacte paginatitel */
.vpn_ipcatcher_dashboard .topbar {
  background: transparent;
  border: 0;
  border-radius: 0;
  box-shadow: none;
  padding: 8px 6px 14px;
  margin: 0;
  text-align: center;
}

.vpn_ipcatcher_dashboard .title {
  font-size: 24px;
  line-height: 1.2;
  color: #ffffff;
  text-shadow: 0 1px 1px #000000;
}

.vpn_ipcatcher_dashboard .subtitle {
  margin-top: 5px;
  color: #dce5e8;
  font-size: 12px;
}

/* Alle vijf statuskaarten op één regel */
.vpn_ipcatcher_dashboard .grid {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 6px;
  margin: 8px 0;
}

.vpn_ipcatcher_dashboard .card {
  min-height: 88px;
  padding: 10px;
  background: #2f3a3e;
  border: 1px solid #718187;
  border-radius: 2px;
  box-shadow: none;
}

.vpn_ipcatcher_dashboard .card h3 {
  margin: 0 0 7px;
  color: #d8e6eb;
  font-size: 11px;
  letter-spacing: .5px;
}

.vpn_ipcatcher_dashboard .big {
  font-size: 22px;
}

/* Panelen zoals andere Merlin-add-ons */
.vpn_ipcatcher_dashboard .panel {
  margin: 8px 0;
  background: #4d595d;
  border: 1px solid #7c8a90;
  border-radius: 2px;
  box-shadow: none;
  overflow: hidden;
}

.vpn_ipcatcher_dashboard .panel-title {
  padding: 7px 10px;
  background: linear-gradient(to bottom, #7c8a90, #596e74);
  border-bottom: 1px solid #29363a;
  color: #ffffff;
  font-size: 13px;
  text-shadow: 0 1px 1px #000000;
}

.vpn_ipcatcher_dashboard .panel-body {
  padding: 10px;
}

/* Knoppen compacter */
.vpn_ipcatcher_dashboard .actions,
.vpn_ipcatcher_dashboard .helperBar {
  gap: 6px;
}

.vpn_ipcatcher_dashboard .btn {
  padding: 7px 11px;
  background: linear-gradient(to bottom, #465c64, #26373d);
  border: 1px solid #75878d;
  border-radius: 4px;
  color: #ffffff;
  font-size: 12px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.12);
}

.vpn_ipcatcher_dashboard .btn:hover {
  background: linear-gradient(to bottom, #58717a, #30464d);
}

.vpn_ipcatcher_dashboard .btn.green {
  background: linear-gradient(to bottom, #31895a, #1f603f);
}

.vpn_ipcatcher_dashboard .btn.red {
  background: linear-gradient(to bottom, #a04a4a, #733232);
}

.vpn_ipcatcher_dashboard .btn.orange {
  background: linear-gradient(to bottom, #b77922, #805315);
}

.vpn_ipcatcher_dashboard .btn.blue {
  background: linear-gradient(to bottom, #3c83b5, #27638d);
}

/* Hoofdtabs */
.vpn_ipcatcher_dashboard .layoutTabs,
.vpn_ipcatcher_dashboard .tabs {
  gap: 4px;
}

.vpn_ipcatcher_dashboard .layoutTabs {
  margin: 8px 0 4px;
}

.vpn_ipcatcher_dashboard .layoutTab,
.vpn_ipcatcher_dashboard .tab {
  padding: 7px 12px;
  background: linear-gradient(to bottom, #354950, #1d2c31);
  border: 1px solid #718187;
  border-radius: 3px;
  color: #ffffff;
  font-size: 13px;
}

.vpn_ipcatcher_dashboard .layoutTab.active,
.vpn_ipcatcher_dashboard .tab.active {
  background: linear-gradient(to bottom, #4b91c1, #2d6e9a);
  border-color: #91b3ca;
}

/* Tabellen */
.vpn_ipcatcher_dashboard table.data {
  background: #2f3a3e;
  border: 1px solid #748388;
  border-radius: 0;
}

.vpn_ipcatcher_dashboard table.data th {
  background: #39484d;
  color: #dce8eb;
  font-size: 11px;
}

.vpn_ipcatcher_dashboard table.data td {
  background: #2f3a3e;
  border-bottom-color: #48595e;
}

/* Formuliervelden */
.vpn_ipcatcher_dashboard .formgrid input,
.vpn_ipcatcher_dashboard .formgrid select,
.vpn_ipcatcher_dashboard .formgrid textarea,
.vpn_ipcatcher_dashboard .search input {
  background: #263438;
  border: 1px solid #78898e;
  border-radius: 3px;
}

.vpn_ipcatcher_dashboard .note {
  background: #34464b;
  border-left-color: #55a6db;
  border-radius: 2px;
}

.vpn_ipcatcher_dashboard pre {
  background: #273539;
  border-color: #748388;
  border-radius: 2px;
}

.vpn_ipcatcher_dashboard .split {
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 8px;
}

.vpn_ipcatcher_dashboard .footer {
  margin: 14px 0 4px;
  color: #d0dadd;
  text-align: center;
}

/* Responsive */
@media (max-width: 1100px) {
  .vpn_ipcatcher_dashboard .grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .vpn_ipcatcher_dashboard .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .vpn_ipcatcher_dashboard .split {
    grid-template-columns: 1fr;
  }
}

/* ASUS_COMPACT_END */
/* VPNIPC_FINAL_LAYOUT_START */

/* Ruimte onder de statuskaarten */
.vpn_ipcatcher_dashboard .grid + .muted {
  display: block;
  clear: both;
  margin: 10px 2px 14px !important;
  line-height: 18px;
}

/* Statuskaarten allemaal even hoog */
.vpn_ipcatcher_dashboard .grid {
  align-items: stretch;
  margin-bottom: 0;
}

.vpn_ipcatcher_dashboard .card {
  min-height: 112px;
}

.vpn_ipcatcher_dashboard .card .muted {
  font-size: 11px;
  line-height: 1.25;
  overflow-wrap: anywhere;
  word-break: normal;
}

/* Iets meer afstand vóór Actions */
.vpn_ipcatcher_dashboard .grid + .muted + .panel {
  margin-top: 0;
}

/* Titelblok iets compacter */
.vpn_ipcatcher_dashboard .topbar {
  padding-top: 10px;
  padding-bottom: 12px;
}

/* VPNIPC_FINAL_LAYOUT_END */

/* VPNIPC_LIVE_LAYOUT_V10_START */
.vpn_ipcatcher_dashboard #page_live .panel-body{padding:16px}
.vpn_ipcatcher_dashboard #page_live .tabs{display:grid;grid-template-columns:repeat(7,minmax(110px,1fr));gap:8px;margin:0 0 18px}
.vpn_ipcatcher_dashboard #page_live .tab{width:100%;min-height:42px;padding:9px 10px;line-height:1.2;text-align:center;white-space:normal}
.vpn_ipcatcher_dashboard #liveOutput{margin-top:0}
.vpn_ipcatcher_dashboard #liveOutput>pre,.vpn_ipcatcher_dashboard #liveOutput .ipsetDump>pre{margin:0 0 18px;padding:16px 18px;line-height:1.55;max-height:320px}
.vpn_ipcatcher_dashboard #liveOutput .scroll{margin-top:0;border:1px solid #718187;border-radius:3px}
.vpn_ipcatcher_dashboard #liveOutput table.data{table-layout:auto;margin:0;border:0}
.vpn_ipcatcher_dashboard #liveOutput table.data th,.vpn_ipcatcher_dashboard #liveOutput table.data td{padding:11px 14px;line-height:1.35}
.vpn_ipcatcher_dashboard #liveOutput table.data th{white-space:nowrap}
.vpn_ipcatcher_dashboard #liveOutput table.data td.mono{white-space:nowrap}
.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data th:nth-child(1),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:nth-child(1){width:18%}
.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data th:nth-child(2),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:nth-child(2),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data th:nth-child(3),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:nth-child(3),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data th:nth-child(4),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:nth-child(4){width:12%}
.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data th:nth-child(5),.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:nth-child(5){width:20%}
.vpn_ipcatcher_dashboard #liveOutput .ipsetDump table.data td:last-child{white-space:normal;overflow-wrap:anywhere}
@media(max-width:1150px){.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(4,minmax(130px,1fr))}}
@media(max-width:760px){.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(2,minmax(0,1fr))}.vpn_ipcatcher_dashboard #liveOutput{overflow-x:auto}.vpn_ipcatcher_dashboard #liveOutput table.data{min-width:850px}}
/* VPNIPC_LIVE_LAYOUT_V10_END */


/* VPNIPC_I18N_V11_START */
.vpn_ipcatcher_dashboard .languageRow{
  display:flex;
  justify-content:flex-end;
  align-items:center;
  gap:7px;
  margin:-2px 0 5px;
  min-height:28px;
}
.vpn_ipcatcher_dashboard .languageRow label{
  color:#dce5e8;
  font-size:11px;
  font-weight:700;
}
.vpn_ipcatcher_dashboard .languageRow select{
  min-width:128px;
  padding:4px 7px;
  background:#263438;
  color:#fff;
  border:1px solid #78898e;
  border-radius:3px;
  font-size:11px;
}
@media(max-width:760px){
  .vpn_ipcatcher_dashboard .languageRow{justify-content:center;margin-bottom:7px}
}
/* VPNIPC_I18N_V11_END */

/* Scoped operational layout; leave Merlin's surrounding navigation untouched. */
.vpn_ipcatcher_dashboard .wrap{padding:12px}
.vpn_ipcatcher_dashboard .topbar{margin-bottom:6px}
.vpn_ipcatcher_dashboard .grid{margin:8px 0;gap:8px}
.vpn_ipcatcher_dashboard .grid .card{min-height:76px;padding:10px}
.vpn_ipcatcher_dashboard .grid .card .big{font-size:22px}
.vpn_ipcatcher_dashboard .liveFilters{display:flex;flex-wrap:wrap;gap:8px;align-items:end;margin:10px 0}
.vpn_ipcatcher_dashboard #flowControls{display:contents}
.vpn_ipcatcher_dashboard .liveFilters label{display:flex;flex:1 1 130px;flex-direction:column;gap:4px;font-size:12px;min-width:0}
.vpn_ipcatcher_dashboard .liveFilters input,.vpn_ipcatcher_dashboard .liveFilters select{box-sizing:border-box;width:100%;min-width:0;padding:7px;background:#263235;color:#edf3f3;border:1px solid #637375;border-radius:3px}
.vpn_ipcatcher_dashboard #diagnosticControls label{flex:1 1 240px}
.vpn_ipcatcher_dashboard #diagnosticControls [data-i18n="diagnosticDnsNote"],.vpn_ipcatcher_dashboard #diagnosticControls [data-i18n="diagnosticLimited"]{flex-basis:100%}
.vpn_ipcatcher_dashboard #diagnosticProgress{width:160px;height:10px;accent-color:#69c6b6}
.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(9,minmax(0,1fr));gap:5px;margin-bottom:10px}
.vpn_ipcatcher_dashboard #page_live .tab{padding:7px 4px;font-size:12px;border-radius:3px}
.vpn_ipcatcher_dashboard #liveOutput table.data td,.vpn_ipcatcher_dashboard #liveOutput table.data th{padding:7px 9px}
@media(max-width:1100px){.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(3,minmax(0,1fr))}}
@media(max-width:600px){.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(3,minmax(0,1fr))}}
.vpn_ipcatcher_dashboard{background:#263235;color:#edf3f3}
.vpn_ipcatcher_dashboard .topbar{text-align:left;padding:12px 0}
.vpn_ipcatcher_dashboard .title{font-size:22px;text-shadow:none}
.vpn_ipcatcher_dashboard .subtitle{display:none}
.vpn_ipcatcher_dashboard .panel{background:transparent;border:0;border-radius:0;margin:16px 0}
.vpn_ipcatcher_dashboard .panel-title{background:transparent;border-bottom:1px solid #536365;padding:10px 0;text-shadow:none}
.vpn_ipcatcher_dashboard .panel-body{padding:12px 0}
.vpn_ipcatcher_dashboard .card{background:#344245;border-color:#59686a;border-radius:4px;min-height:108px}
.vpn_ipcatcher_dashboard .card h3,.vpn_ipcatcher_dashboard table.data th{letter-spacing:0}
.vpn_ipcatcher_dashboard .card .muted{overflow-wrap:anywhere}
.vpn_ipcatcher_dashboard .layoutTabs{gap:0;border-bottom:1px solid #637375}
.vpn_ipcatcher_dashboard .layoutTab{background:transparent;border:0;border-bottom:3px solid transparent;border-radius:0;padding:12px;font-size:14px}
.vpn_ipcatcher_dashboard .layoutTab.active{background:transparent;border-color:#67c6b8;color:#b5eee2}
.vpn_ipcatcher_dashboard .tabs{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:6px}
.vpn_ipcatcher_dashboard .tab{min-width:0;white-space:normal;overflow-wrap:anywhere;padding:10px 6px;font-size:13px;line-height:1.4}
.vpn_ipcatcher_dashboard .presetGrid{align-items:start}
.vpn_ipcatcher_dashboard .presetCard{background:transparent;border:0;border-top:2px solid #687e80;border-radius:0;padding:14px 0}
.vpn_ipcatcher_dashboard .presetItem{min-width:0;align-items:start}
.vpn_ipcatcher_dashboard .presetMeta{overflow-wrap:anywhere}
.vpn_ipcatcher_dashboard details summary{cursor:pointer;color:#bce1df;padding:8px 0}
.vpn_ipcatcher_dashboard .previewList{max-height:250px;overflow:auto;line-height:1.6;overflow-wrap:anywhere}
.vpn_ipcatcher_dashboard .settingsGroup{margin:16px 0;border:0;border-top:1px solid #536365;padding:12px 0}
.vpn_ipcatcher_dashboard .settingsGroup legend{font-weight:700;padding-right:12px;color:#b5eee2}
.vpn_ipcatcher_dashboard .formgrid input[readonly]{opacity:.8;border-style:dashed;cursor:default}
.vpn_ipcatcher_dashboard .saveBar{position:sticky;bottom:0;background:#263235;padding:12px 0;border-top:1px solid #536365;z-index:2}
.vpn_ipcatcher_dashboard [hidden]{display:none!important}
.vpn_ipcatcher_dashboard .sessionMeta{display:flex;gap:16px;flex-wrap:wrap;margin-top:10px;color:#bce1df;font-size:13px}
.vpn_ipcatcher_dashboard .maintenance{margin-top:10px}
.vpn_ipcatcher_dashboard .note{background:transparent;border-radius:0;color:#c7d8d8}
.vpn_ipcatcher_dashboard .languageRow{float:right;margin:0 0 4px 12px}
.vpn_ipcatcher_dashboard .topbar{display:flow-root;padding:8px 0}
.vpn_ipcatcher_dashboard .sessionMeta{margin-top:6px}
.vpn_ipcatcher_dashboard .panel{margin:10px 0}
.vpn_ipcatcher_dashboard .panel-title{padding:7px 0}
.vpn_ipcatcher_dashboard .panel-body{padding:8px 0}
.vpn_ipcatcher_dashboard .layoutTab{padding:8px 10px}
.vpn_ipcatcher_dashboard #page_live .tabs{grid-template-columns:repeat(3,minmax(0,1fr))}
.vpn_ipcatcher_dashboard #page_live .tab{height:auto;min-height:38px;overflow-wrap:normal;word-break:normal;line-height:1.4}
@media(max-width:600px){.vpn_ipcatcher_dashboard .languageRow{float:none;margin:0 0 7px}}
@media(max-width:600px){.vpn_ipcatcher_dashboard .grid{grid-template-columns:repeat(2,minmax(0,1fr))}.vpn_ipcatcher_dashboard .tabs{grid-template-columns:repeat(2,minmax(0,1fr))}.vpn_ipcatcher_dashboard .languageRow{justify-content:flex-start}.vpn_ipcatcher_dashboard .layoutTab{padding:10px 8px;font-size:13px}.vpn_ipcatcher_dashboard .split{grid-template-columns:1fr}}
</style>

<script>
// ASUS MENU INIT FUNCTIE
function initial() {
  show_menu();
}

var custom_settings = <% get_custom_settings(); %>;
if(!custom_settings || typeof custom_settings !== 'object') custom_settings = {}; // Alleen voor compatibiliteit; config gebruikt de rc-service stream.

var dataCache = null, dirty = false, currentTab = 'flows', currentPage = 'overview', actionBusy = false;
var diagnosticUntil=0,diagnosticBusy=false;
var diagnosticState='idle',diagnosticError='',diagnosticClientsBusy=false;
var diagnosticHistory=[],diagnosticPrevious={},diagnosticSnapshotKey='';
var diagnosticDnsSeen={},diagnosticDomains={};
var liveScrollPositions={},renderedLiveTab='';
var PRESET_CATEGORIES = [], protectedPresetIps = [], configLoaded = false, pendingPresetKeys = {};
var loadedConfigRevision = '', externalConfigWarningShown = false;



/* VPNIPC_I18N_V11_START */
var vpnipcLanguageMode='auto', vpnipcCurrentLanguage='nl';
var VPNIPC_I18N={
  nl:{
    waiting:'Wachtlijst',
    browserTitle:'VPN IP Catcher - ASUS Merlin', language:'Taal', autoRouter:'Automatisch (router)', updated:'bijgewerkt', openResolvedIps:'Opgeloste IP’s openen', openExcludeRanges:'Uitsluitbereiken openen',
    title:'VPN IP Catcher-dashboard', subtitle:'ASUS Merlin WebUI - stabiele runtime en betere uitsluitingen/presets',
    engine:'Service', finalIps:'VPN-bestemmingen', candidateIps:'In beoordeling', candidateHint:'tijdelijke leerset',
    excludeCache:'DNS-uitsluitingen', excludeCacheHint:'tijdelijk opgeloste domein-IP’s', excludeRanges:'Uitgesloten netwerken', fixedRanges:'vaste CIDR-bereiken',
    actions:'Acties', start:'Start', stop:'Stop', restart:'Herstarten', refreshStatus:'Status vernieuwen', resolveExcludes:'Uitsluitingen oplossen',
    safeBaseExcludes:'Veilige basisuitsluitingen', repairSafeExcludes:'Veilige uitsluitingen herstellen', cleanExcludedIps:'Uitgesloten IP’s opruimen', clearLog:'Log wissen',
    overview:'Overzicht', liveView:'Liveweergave', config:'Configuratie', exclusions:'Uitsluitingen', presetLists:'Presetlijsten',
    capture:'Verkeer vastleggen', sourceIps:'Bron-IP’s', tip:'Tip', quickLinks:'Snelkoppelingen',
    openLiveFlows:'Liveflows openen', openStatus:'Status openen', openPresetLists:'Presetlijsten openen', openConfig:'Configuratie openen', openExclusions:'Uitsluitingen openen',
    liveFlows:'Liveflows', log:'Log', status:'Status', candidate:'Kandidaat', final:'Definitief', resolvedIps:'Opgeloste IP’s',
    configuration:'Configuratie', configNote:'Wijzigingen worden opgeslagen in /jffs/scripts/vpn_ipcatcher.conf. Presetvinkjes wijzigen direct de velden hieronder, maar worden pas definitief na Config opslaan of Opslaan + herstarten.',
    interfaces:'Interfaces', ipsetName:'IPSet-naam', ports:'Poorten', promoteMode:'Promotiemodus', promoteInterval:'Promotie-interval', minAge:'Minimale leeftijd', minBytes:'Minimale bytes',
    candidateTimeout:'Kandidaat-time-out', finalTimeout:'Definitieve time-out', streamFlowScan:'Streamflow-scan', sourceIpsLabel:'Bron-IP’s', streamScanInterval:'Streamscan-interval',
    streamMinBytes:'Minimale streambytes', streamMinDelta:'Minimale streamtoename', requireGrowth:'Verkeerstoename vereist', streamTarget:'Streamdoel', excludeResolver:'Uitsluitresolver',
    resolverInterval:'Resolverinterval', reverseDnsCheck:'Omgekeerde DNS-controle', genericHostScan:'Generieke hostscan', externalDns:'Externe DNS', externalDnsServer:'Externe DNS-server',
    retryDelay:'Wachttijd opnieuw proberen', maxRetryDelay:'Maximale wachttijd', excludeIps:'Uitgesloten IP’s', excludeNets:'Uitgesloten netwerken/bereiken', excludeDomains:'Uitgesloten domeinen',
    saveConfig:'Configuratie opslaan', saveRestart:'Opslaan + herstarten', reloadConfig:'Opnieuw laden uit configuratie', currentConfigExclusions:'Huidige configuratie-uitsluitingen',
    domains:'Domeinen', ips:'IP’s', ranges:'Bereiken', notes:'Toelichting',
    presetSearch:'Zoek op naam, domein of bereik…', selectAllVisible:'Alles zichtbaars selecteren', clearVisible:'Zichtbare selectie wissen',
    footer:'vpn_ipcatcher UI v11 - ASUS Merlin-integratie',
    running:'ACTIEF', stopped:'GESTOPT', loading:'LADEN', noData:'Geen gegevens.',
    bytes:'Bytes', source:'Bron', destination:'Bestemming', port:'Poort', cand:'Kand.', hint:'Hint', timestamp:'Tijdstip', message:'Bericht', field:'Veld', value:'Waarde', timeout:'Time-out', packets:'Pakketten', seen:'Gezien', hostnameDomain:'Hostnaam / domein', range:'Bereik', comment:'Opmerking',
    serviceRunning:'Service draait en de workerprocessen zijn actief.', serviceStopped:'Service staat uit.', allDevices:'alle apparaten (LAN + Wi-Fi) - meer ruis',
    configPreparing:'Configuratie voorbereiden', configSending:'Configuratie verzenden', restartStarted:'Herstart gestart', saveFinishing:'Opslag afronden',
    configNotLoaded:'Configuratie is nog niet geladen; wacht op de statusverversing.', sendingConfig:'Configuratie wordt veilig naar de router gestuurd…', actionSent:'Actie verzonden: {action}…',
    waitingConfirmation:'Wachten op bevestiging van de router…', saveSuccess:'Configuratie is door de router opgeslagen.', saveRestartSuccess:'Configuratie is opgeslagen en de engine is herstart.', actionSuccess:'Actie succesvol uitgevoerd.',
    routerActionFailed:'De router meldde dat de actie is mislukt.', noConfirmation:'Geen bevestiging ontvangen. Controleer /jffs/scripts/service-event.', externalChanged:'De configuratie is intussen via amtm gewijzigd. Sla lokaal op of kies Opnieuw laden uit configuratie.',
    localDiscarded:'Lokale wijzigingen zijn verworpen; de configuratie wordt opnieuw geladen.', addedConfig:'Toegevoegd aan configuratie: ', removedConfig:'Verwijderd uit configuratie: ', rememberSave:' - vergeet Configuratie opslaan of Opslaan + herstarten niet',
    presetsLoading:'Presetdatabase wordt geladen…', presetLoadFailed:'Presetdatabase kon niet worden geladen: ', jsonFailed:'JSON kon niet worden gelezen. Fout: ',
    auto:'automatisch', age:'leeftijd', immediate:'direct', yes:'ja', no:'nee', candidateValue:'kandidaat', finalValue:'definitief', emptyAllDevices:'leeg = alle apparaten', empty:'leeg',
    cat_dns:'DNS-providers', cat_social:'Sociaal / berichten', cat_cameras:'Beveiligingscamera’s / IoT-cloud', cat_github:'GitHub / ontwikkel-CDN', cat_games:'Games / downloads', cat_updates:'Besturingssysteem- / app-updates', cat_tv:'Smart-tv-telemetrie', cat_streaming:'Streamingdiensten',
    note_dns:'Meestal uitsluiten zodat DNS-resolvers nooit via VPN Director worden geleerd.', note_social:'Voorkomt dat Meta, WhatsApp, Instagram en Snapchat als bijvangst worden geleerd.', note_cameras:'Sluit camera- en IoT-cloudverkeer uit.', note_github:'Voorkomt dat GitHub/CDN-verkeer als stream wordt geleerd.', note_games:'Voorkomt dat grote gamedownloads als stream worden geleerd.', note_updates:'Sluit updates en software-CDN-verkeer uit.', note_tv:'Vermindert achtergrond- en telemetrieverkeer van smart-tv-platformen.', note_streaming:'Alleen inschakelen voor diensten die juist NIET via deze VPN-regel mogen.',
    domainsCount:'domeinen', rangesCount:'bereiken', detailsDomains:'Domeinen', detailsRanges:'Bereiken'
  },
  en:{
    waiting:'Waiting',
    browserTitle:'VPN IP Catcher - ASUS Merlin', language:'Language', autoRouter:'Auto (router)', updated:'updated', openResolvedIps:'Open resolved IPs', openExcludeRanges:'Open exclude ranges',
    title:'VPN IP Catcher Dashboard', subtitle:'ASUS Merlin WebUI - stable runtime and improved exclusions/presets',
    engine:'Service', finalIps:'VPN destinations', candidateIps:'Under review', candidateHint:'temporary learning set',
    excludeCache:'DNS exclusions', excludeCacheHint:'temporarily resolved domain IPs', excludeRanges:'Excluded networks', fixedRanges:'fixed CIDR ranges',
    actions:'Actions', start:'Start', stop:'Stop', restart:'Restart', refreshStatus:'Refresh status', resolveExcludes:'Resolve exclusions',
    safeBaseExcludes:'Safe base exclusions', repairSafeExcludes:'Repair safe exclusions', cleanExcludedIps:'Clean excluded IPs', clearLog:'Clear log',
    overview:'Overview', liveView:'Live view', config:'Configuration', exclusions:'Exclusions', presetLists:'Preset lists',
    capture:'Capture', sourceIps:'Source IPs', tip:'Tip', quickLinks:'Quick links',
    openLiveFlows:'Open live flows', openStatus:'Open status', openPresetLists:'Open preset lists', openConfig:'Open configuration', openExclusions:'Open exclusions',
    liveFlows:'Live flows', log:'Log', status:'Status', candidate:'Candidate', final:'Final', resolvedIps:'Resolved IPs',
    configuration:'Configuration', configNote:'Changes are stored in /jffs/scripts/vpn_ipcatcher.conf. Preset checkboxes update the fields below immediately, but become permanent only after Save configuration or Save + restart.',
    interfaces:'Interfaces', ipsetName:'IPSet name', ports:'Ports', promoteMode:'Promote mode', promoteInterval:'Promote interval', minAge:'Minimum age', minBytes:'Minimum bytes',
    candidateTimeout:'Candidate timeout', finalTimeout:'Final timeout', streamFlowScan:'Stream flow scan', sourceIpsLabel:'Source IPs', streamScanInterval:'Stream scan interval',
    streamMinBytes:'Stream minimum bytes', streamMinDelta:'Stream minimum delta', requireGrowth:'Require traffic growth', streamTarget:'Stream target', excludeResolver:'Exclusion resolver',
    resolverInterval:'Resolver interval', reverseDnsCheck:'Reverse DNS check', genericHostScan:'Generic host scan', externalDns:'External DNS', externalDnsServer:'External DNS server',
    retryDelay:'Retry delay', maxRetryDelay:'Maximum retry delay', excludeIps:'Exclude IPs', excludeNets:'Exclude networks/ranges', excludeDomains:'Exclude domains',
    saveConfig:'Save configuration', saveRestart:'Save + restart', reloadConfig:'Reload from configuration', currentConfigExclusions:'Current configuration exclusions',
    domains:'Domains', ips:'IPs', ranges:'Ranges', notes:'Notes',
    presetSearch:'Search by name, domain or range…', selectAllVisible:'Select all visible', clearVisible:'Clear visible',
    footer:'vpn_ipcatcher UI v11 - ASUS Merlin integration',
    running:'RUNNING', stopped:'STOPPED', loading:'LOADING', noData:'No data.',
    bytes:'Bytes', source:'Source', destination:'Destination', port:'Port', cand:'Cand', hint:'Hint', timestamp:'Timestamp', message:'Message', field:'Field', value:'Value', timeout:'Timeout', packets:'Packets', seen:'Seen', hostnameDomain:'Hostname / domain', range:'Range', comment:'Comment',
    serviceRunning:'Service is running and the worker processes are active.', serviceStopped:'Service is stopped.', allDevices:'all devices (LAN + Wi-Fi) - more noise',
    configPreparing:'Preparing configuration', configSending:'Sending configuration', restartStarted:'Restart started', saveFinishing:'Finishing save',
    configNotLoaded:'Configuration has not loaded yet; wait for the status refresh.', sendingConfig:'Sending configuration safely to the router…', actionSent:'Action sent: {action}…',
    waitingConfirmation:'Waiting for confirmation from the router…', saveSuccess:'Configuration was saved by the router.', saveRestartSuccess:'Configuration was saved and the engine restarted.', actionSuccess:'Action completed successfully.',
    routerActionFailed:'The router reported that the action failed.', noConfirmation:'No confirmation received. Check /jffs/scripts/service-event.', externalChanged:'The configuration was changed through amtm. Save the local version or choose Reload from configuration.',
    localDiscarded:'Local changes were discarded; reloading the configuration.', addedConfig:'Added to configuration: ', removedConfig:'Removed from configuration: ', rememberSave:' - remember to use Save configuration or Save + restart',
    presetsLoading:'Loading preset database…', presetLoadFailed:'Preset database could not be loaded: ', jsonFailed:'JSON could not be read. Error: ',
    auto:'auto', age:'age', immediate:'immediate', yes:'yes', no:'no', candidateValue:'candidate', finalValue:'final', emptyAllDevices:'empty = all devices', empty:'empty',
    cat_dns:'DNS providers', cat_social:'Social / messaging', cat_cameras:'Security cameras / IoT cloud', cat_github:'GitHub / dev CDN', cat_games:'Games / downloads', cat_updates:'OS / app updates', cat_tv:'Smart TV telemetry', cat_streaming:'Streaming services',
    note_dns:'Usually exclude these so DNS resolvers are never learned through VPN Director.', note_social:'Prevents Meta, WhatsApp, Instagram and Snapchat from being learned as collateral traffic.', note_cameras:'Excludes camera and IoT cloud traffic.', note_github:'Prevents GitHub/CDN traffic from being learned as a stream.', note_games:'Prevents large game downloads from being learned as streams.', note_updates:'Excludes updates and software CDN traffic.', note_tv:'Reduces background and telemetry traffic from smart TV platforms.', note_streaming:'Enable only for services that should NOT use this VPN rule.',
    domainsCount:'domains', rangesCount:'ranges', detailsDomains:'Domains', detailsRanges:'Ranges'
  }
};
var VPNIPC_CATEGORY_KEYS={
  'DNS providers':'cat_dns','Social / messaging':'cat_social','Security cameras / IoT cloud':'cat_cameras','GitHub / dev CDN':'cat_github',
  'Games / downloads':'cat_games','OS / app updates':'cat_updates','Smart TV telemetry':'cat_tv','Streamingdiensten':'cat_streaming'
};
var VPNIPC_CATEGORY_NOTE_KEYS={
  'DNS providers':'note_dns','Social / messaging':'note_social','Security cameras / IoT cloud':'note_cameras','GitHub / dev CDN':'note_github',
  'Games / downloads':'note_games','OS / app updates':'note_updates','Smart TV telemetry':'note_tv','Streamingdiensten':'note_streaming'
};
var VPNIPC_PRESET_LABEL_NL={
  upd_apple:'Apple / iCloud-updates',upd_google:'Google / Android-updates',tv_samsung:'Samsung Smart TV-telemetrie',tv_philips:'Philips Smart TV-telemetrie',tv_android:'Android TV-telemetrie',tv_lg:'LG Smart TV-telemetrie'
};
function vpnipcRouterLanguage(){
  var raw=String((byId('routerPreferredLang')||{}).value||'').toLowerCase();
  return raw.indexOf('nl')===0?'nl':'en';
}
function vpnipcResolveLanguage(mode){return mode==='nl'||mode==='en'?mode:vpnipcRouterLanguage();}
Object.assign(VPNIPC_I18N.nl,{title:'VPN IP Catcher',version:'Versie',devices:'Apparaten en verbinding',learning:'Verkeer leren',advanced:'Geavanceerde instellingen',maintenance:'Onderhoud',details:'Details',presetOn:'Uitgesloten',presetOff:'Niet uitgesloten',presetPart:'Gedeeltelijk',unsaved:'Niet-opgeslagen wijzigingen',footer:'VPN IP Catcher | ASUS Merlin'});
Object.assign(VPNIPC_I18N.en,{title:'VPN IP Catcher',version:'Version',devices:'Devices and connection',learning:'Traffic learning',advanced:'Advanced settings',maintenance:'Maintenance',details:'Details',presetOn:'Excluded',presetOff:'Not excluded',presetPart:'Partial',unsaved:'Unsaved changes',footer:'VPN IP Catcher | ASUS Merlin'});
Object.assign(VPNIPC_I18N.nl,{trafficVolume:'Verkeer',filterSearch:'Zoeken',filterAll:'Alles',filterSource:'Bronapparaat',filterPort:'Poort',filterState:'Lijststatus',filterFinal:'Definitieve lijst',filterCandidate:'Kandidaat',filterExcluded:'Uitgesloten',filterOther:'Overige',filterClear:'Filters wissen',filterRows:'regels'});
Object.assign(VPNIPC_I18N.en,{trafficVolume:'Traffic',filterSearch:'Search',filterAll:'All',filterSource:'Source device',filterPort:'Port',filterState:'List status',filterFinal:'Final list',filterCandidate:'Candidate',filterExcluded:'Excluded',filterOther:'Other',filterClear:'Clear filters',filterRows:'rows'});
function t(key,vars){
  var table=VPNIPC_I18N[vpnipcCurrentLanguage]||VPNIPC_I18N.en;
  var value=(table[key]!==undefined?table[key]:(VPNIPC_I18N.en[key]!==undefined?VPNIPC_I18N.en[key]:key));
  if(vars) Object.keys(vars).forEach(function(k){value=String(value).replace(new RegExp('\\{'+k+'\\}','g'),vars[k]);});
  return value;
}
function vpnipcSetText(id,key){var e=byId(id); if(e)e.textContent=t(key);}
function vpnipcApplyStaticLanguage(){
  document.documentElement.lang=vpnipcCurrentLanguage==='nl'?'nl':'en';
  document.title=t('browserTitle');
  document.querySelectorAll('.vpn_ipcatcher_dashboard [data-i18n]').forEach(function(e){e.textContent=t(e.getAttribute('data-i18n'));});
  document.querySelectorAll('.vpn_ipcatcher_dashboard [data-i18n-placeholder]').forEach(function(e){e.setAttribute('placeholder',t(e.getAttribute('data-i18n-placeholder')));});
  document.querySelectorAll('.vpn_ipcatcher_dashboard [data-i18n-html]').forEach(function(e){
    var key=e.getAttribute('data-i18n-html');
    if(key==='overviewTip') e.innerHTML=vpnipcCurrentLanguage==='nl'?'Gebruik <strong>Presetlijsten</strong> om uitsluitingen direct in de configuratievelden te zetten. Sla daarna op via <strong>Configuratie opslaan</strong> of <strong>Opslaan + herstarten</strong>.':'Use <strong>Preset lists</strong> to add exclusions directly to the configuration fields. Then use <strong>Save configuration</strong> or <strong>Save + restart</strong>.';
    if(key==='resolvedNote') e.innerHTML=vpnipcCurrentLanguage==='nl'?'<b>Opgeloste IP’s</b> zijn tijdelijke losse adressen uit DNS en verschijnen bij Uitsluitcache. Alleen expliciete CIDR-netwerken uit <b>EXCLUDE_NETS</b> verschijnen bij Uitsluitbereiken.':'<b>Resolved IPs</b> are temporary individual addresses obtained from DNS and appear under Exclude cache. Only explicit CIDR networks from <b>EXCLUDE_NETS</b> appear under Exclude ranges.';
    if(key==='configFieldsNote') e.innerHTML=vpnipcCurrentLanguage==='nl'?'Deze tab toont de <b>configuratievelden</b> zoals de WebGUI ze opslaat. Omdat amtm en de WebGUI dezelfde configuratie gebruiken, horen beide dezelfde status te tonen.':'This tab shows the <b>configuration fields</b> as stored by the WebGUI. Because amtm and the WebGUI use the same configuration, both should show the same status.';
    if(key==='presetNote') e.innerHTML=vpnipcCurrentLanguage==='nl'?'Vink een preset aan om de bijbehorende domeinen/IP’s/bereiken direct in de configuratievelden te zetten. Haal het vinkje weg om ze te verwijderen. Gebruik daarna <b>Configuratie opslaan</b> of <b>Opslaan + herstarten</b>.':'Select a preset to add its domains/IPs/ranges directly to the configuration fields. Clear it to remove them. Then use <b>Save configuration</b> or <b>Save + restart</b>.';
    if(key==='presetStatus') e.innerHTML='<span class="statusOn">'+escapeHtml(t('presetOn'))+'</span> · <span class="statusPart">'+escapeHtml(t('presetPart'))+'</span> · <span class="statusOff">'+escapeHtml(t('presetOff'))+'</span> · * '+escapeHtml(t('unsaved'));
  });
  var selector=byId('vpnipcLanguage'); if(selector)selector.value=vpnipcLanguageMode;
}
function vpnipcApplyLanguage(){
  vpnipcCurrentLanguage=vpnipcResolveLanguage(vpnipcLanguageMode);
  vpnipcApplyStaticLanguage();
  if(dataCache) updateOverview(dataCache);
  renderLiveTab();
  renderPresets();
}
function vpnipcChangeLanguage(value){
  vpnipcLanguageMode=(value==='nl'||value==='en')?value:'auto';
  try{localStorage.setItem('vpnipc_language',vpnipcLanguageMode);}catch(e){}
  vpnipcApplyLanguage();
}
function vpnipcInitLanguage(){
  try{vpnipcLanguageMode=localStorage.getItem('vpnipc_language')||'auto';}catch(e){vpnipcLanguageMode='auto';}
  if(vpnipcLanguageMode!=='auto'&&vpnipcLanguageMode!=='nl'&&vpnipcLanguageMode!=='en')vpnipcLanguageMode='auto';
  vpnipcCurrentLanguage=vpnipcResolveLanguage(vpnipcLanguageMode);
  vpnipcApplyStaticLanguage();
}
/* VPNIPC_I18N_V11_END */

function byId(id){return document.getElementById(id)}
function setText(id,v){var e=byId(id); if(e) e.textContent=(v===undefined||v===null)?'':v}
function escapeHtml(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}
function badge(engine){var e=byId('engineBadge'); if(!e) return; e.className='badge '+(engine==='running'?'ok':'bad'); e.textContent=engine==='running'?t('running'):t('stopped')}
function showToast(t){setText('toast',t); setTimeout(function(){setText('toast','')},4500)}
function getWords(v){return String(v||'').trim().split(/\s+/).filter(Boolean)}
function mergeUnique(current, add){var seen={}, out=[]; getWords(current).forEach(function(x){if(!seen[x]){seen[x]=1;out.push(x)}}); (add||[]).forEach(function(x){if(x&&!seen[x]){seen[x]=1;out.push(x)}}); return out.join(' ')}
function removeWords(current, remList){var rem={}; (remList||[]).forEach(function(x){rem[x]=1}); return getWords(current).filter(function(x){return !rem[x]}).join(' ')}
function decodeText(txt){txt=String(txt||''); if(txt.indexOf('\\n')>=0) txt=txt.replace(/\\n/g,'\n'); return txt.trim()}
function splitCompactLines(txt){txt=decodeText(txt); if(txt.indexOf('\n')!==-1) return txt; return txt.replace(/\s(?=Name:|Type:|Header:|Revision:|Size in memory:|References:|Number of entries:|Members:|IP\s+timeout|Bytes\s+Source)/g,'\n').replace(/\s(?=\d{12}\s+\d{1,3}\.)/g,'\n').replace(/\s(?=\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+timeout=)/g,'\n').replace(/\s(?=\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/g,'\n')}

function applyStatusData(d){
  dataCache=d;
  if(Array.isArray(d.protected_ips)) protectedPresetIps=d.protected_ips;
  updateOverview(d);
  fillConfig(d.config,d.config_revision);
  renderLiveTab();
  renderPresets();
}
function waitForActionResult(nonce, attempts){
  return fetch('/user/vpn_ipcatcher_status.json?ts='+Date.now(),{cache:'no-store'})
    .then(function(r){if(!r.ok) throw new Error('status HTTP '+r.status); return r.json();})
    .then(function(d){
      applyStatusData(d);
      if(String(d.last_action_nonce||'')===String(nonce)){
        if(d.last_action_status==='ok') return d;
        throw new Error(d.last_action_message||t('routerActionFailed'));
      }
      if(attempts<=0) throw new Error(t('noConfirmation'));
      return new Promise(function(resolve){setTimeout(resolve,750);})
        .then(function(){return waitForActionResult(nonce,attempts-1);});
    });
}
function base64UrlEncode(text){
  var bytes;
  if(window.TextEncoder){
    bytes=new TextEncoder().encode(text);
    var binary='', step=0x8000;
    for(var i=0;i<bytes.length;i+=step){
      binary+=String.fromCharCode.apply(null,bytes.subarray(i,Math.min(i+step,bytes.length)));
    }
    return btoa(binary).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
  }
  return btoa(unescape(encodeURIComponent(text))).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}
function postRcEvent(eventName){
  var f=byId('vpnipc_form');
  var params=[];
  for(var i=0;i<f.elements.length;i++){
    var el=f.elements[i];
    if(!el.name || el.disabled || ['amng_custom','action_script','action_wait','http_id'].indexOf(el.name)>=0) continue;
    params.push(encodeURIComponent(el.name)+'='+encodeURIComponent(el.value==null?'':el.value));
  }
  var token=(document.cookie.match(/(?:^|; )asus_token=([^;]*)/)||[])[1]||'';
  params.push('action_script='+encodeURIComponent('restart_'+eventName));
  params.push('action_wait=0');
  params.push('http_id='+encodeURIComponent(token));
  return fetch('/start_apply.htm',{
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'},
    body:params.join('&'),
    credentials:'same-origin',
    cache:'no-store'
  }).then(function(r){
    if(!r.ok) throw new Error('router-event HTTP '+r.status);
    return new Promise(function(resolve){setTimeout(function(){resolve(r);},120);});
  });
}
function buildConfigPayload(){
  var keys=['INTERFACES','IPSET_NAME','PORTS','PROMOTE_MODE','PROMOTE_EVERY','MIN_AGE','MIN_BYTES','CANDIDATE_TIMEOUT','FINAL_TIMEOUT','STREAM_FLOW_SCAN','SOURCE_IPS','STREAM_SCAN_EVERY','STREAM_MIN_BYTES','STREAM_MIN_DELTA','STREAM_REQUIRE_GROWTH','STREAM_FLOW_TARGET','EXCLUDE_DOMAINS','EXCLUDE_IPS','EXCLUDE_NETS','EXCLUDE_RESOLVE_CACHE','EXCLUDE_RESOLVE_EVERY','REVERSE_DNS_CHECK','CAPTURE_GENERIC_HOSTNAMES','ALLOW_EXTERNAL_DNS','EXTERNAL_DNS_SERVER','RETRY_DELAY','MAX_RETRY_DELAY'];
  var lines=[];
  keys.forEach(function(k){
    var el=byId('cfg_'+k);
    if(!el) return;
    var value=String(el.value==null?'':el.value).replace(/\r?\n/g,' ').replace(/\s+/g,' ').trim();
    lines.push(k+'='+value);
  });
  return lines.join('\n')+'\n';
}
function sendStreamedConfig(action,nonce){
  var encoded=base64UrlEncode(buildConfigPayload());
  /* Houd de rc-service naam ruim onder de firmwarelimiet, maar voorkom tientallen extra requests. */
  var chunkSize=88;
  var chunks=[];
  for(var i=0;i<encoded.length;i+=chunkSize) chunks.push(encoded.slice(i,i+chunkSize));
  var total=chunks.length+2, sent=0;
  function progress(label){
    sent++;
    setText('toast',label+' ('+sent+'/'+total+')');
  }
  var chain=postRcEvent('vipcR'+nonce).then(function(){progress(t('configPreparing'));});
  chunks.forEach(function(chunk,n){
    chain=chain.then(function(){
      return postRcEvent('vipcA'+nonce+'_'+n+'_'+chunk).then(function(){progress(t('configSending'));});
    });
  });
  var finalAction=(action==='save_config_restart')?'saverestart':'save';
  return chain.then(function(){
    return postRcEvent('vipcZ'+nonce+'_'+finalAction).then(function(){progress(action==='save_config_restart'?t('restartStarted'):t('saveFinishing'));});
  });
}
function sendSimpleAction(action,nonce){
  return postRcEvent('vipcX'+nonce+'_'+action);
}
function applyAction(action){
  var isSave=(action==='save_config' || action==='save_config_restart');
  if(isSave && !configLoaded){showToast(t('configNotLoaded')); return;}
  var buttons=document.querySelectorAll('.vpn_ipcatcher_dashboard button[onclick*="applyAction"]');
  buttons.forEach(function(b){b.disabled=true;});
  actionBusy=true;
  var nonce=Date.now().toString(36);
  showToast(isSave?t('sendingConfig'):t('actionSent',{action:action}));
  var sendPromise=isSave?sendStreamedConfig(action,nonce):sendSimpleAction(action,nonce);
  sendPromise
    .then(function(){setText('toast',t('waitingConfirmation')); return waitForActionResult(nonce,120);})
    .then(function(){
      if(isSave){dirty=false; pendingPresetKeys={}; externalConfigWarningShown=false;}
      showToast(isSave?(action==='save_config_restart'?t('saveRestartSuccess'):t('saveSuccess')):t('actionSuccess'));
    })
    .catch(function(err){showToast('FOUT: '+(err&&err.message?err.message:String(err)));})
    .then(function(){
      buttons.forEach(function(b){b.disabled=false;});
      actionBusy=false;
    });
}

function fillConfig(cfg, revision){
  if(!cfg) return;
  if(dirty){
    if(loadedConfigRevision && revision && revision!==loadedConfigRevision && !externalConfigWarningShown){
      externalConfigWarningShown=true;
      showToast(t('externalChanged'));
    }
    return;
  }
  Object.keys(cfg).forEach(function(k){var el=byId('cfg_'+k); if(el) el.value=(cfg[k]===undefined||cfg[k]===null)?'':cfg[k];});
  configLoaded=true;
  loadedConfigRevision=revision||loadedConfigRevision;
  externalConfigWarningShown=false;
  updateExclusionPreview();
  renderPresets();
}
function discardLocalChanges(){
  dirty=false;
  pendingPresetKeys={};
  externalConfigWarningShown=false;
  showToast(t('localDiscarded'));
  loadStatus();
}

function setPage(page){
  currentPage=page;
  document.querySelectorAll('.vpn_ipcatcher_dashboard .page').forEach(function(x){x.classList.remove('active')});
  document.querySelectorAll('.vpn_ipcatcher_dashboard .layoutTab').forEach(function(x){x.classList.remove('active')});
  var p=byId('page_'+page), b=byId('pageTab_'+page);
  if(p) p.classList.add('active');
  if(b) b.classList.add('active');
  if(page==='presets') renderPresets();
}
function setTab(t){
  currentTab=t;
  if(t==='diagnostic') loadDiagnosticClients();
  document.querySelectorAll('.vpn_ipcatcher_dashboard .tab').forEach(function(x){x.classList.remove('active')});
  var b=byId('tab_'+t); if(b) b.classList.add('active');
  renderLiveTab();
}
function renderTable(headers, rows){
  if(!rows||!rows.length) return '<div class="muted">'+escapeHtml(t('noData'))+'</div>';
  var html='<div class="scroll"><table class="data"><thead><tr>';
  headers.forEach(function(h){html+='<th>'+escapeHtml(h)+'</th>'});
  html+='</tr></thead><tbody>';
  rows.forEach(function(r){html+='<tr>'+r+'</tr>'});
  html+='</tbody></table></div>';
  return html;
}
function td(v, cls){return '<td'+(cls?' class="'+cls+'"':'')+'>'+escapeHtml(v||'')+'</td>'}
function parseKeyValueStatus(txt){
  txt=splitCompactLines(txt);
  var lines=txt.split('\n').map(function(x){return x.trim()}).filter(Boolean), rows=[];
  lines.forEach(function(line){ if(/^(Service|Config|Timers|Activity)$/.test(line)){rows.push({section:true,label:line}); return;} var m=line.match(/^(.+?)\s{2,}(.*)$/); if(m) rows.push({key:m[1].trim(), value:m[2].trim()}); });
  return rows;
}
function parseIpsetDump(txt){
  txt=splitCompactLines(txt);
  var lines=txt.split('\n').map(function(x){return x.trim()}).filter(Boolean);
  var meta=[], rows=[], inMembers=false;

  function prettySeen(v){
    var m=String(v||'').match(/^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})$/);
    return m ? (m[1]+'-'+m[2]+'-'+m[3]+' '+m[4]+':'+m[5]+':'+m[6]) : (v||'');
  }

  lines.forEach(function(line){
    if(line==='Members:' || line.indexOf('Members:')===0){inMembers=true; return;}
    if(!inMembers){meta.push(line); return;}
    if(/^IP\s+timeout/i.test(line)) return;

    /* Huidige ipset-notatie:
       203.0.113.10 timeout 447 packets 0 bytes 0
       comment "src=http-location;seen=20260712-203841"
    */
    var m=line.match(/^([0-9.\/]+)\s+timeout\s+([0-9]+)\s+packets\s+([0-9]+)\s+bytes\s+([0-9]+)(?:\s+comment\s+"([^"]*)")?/i);
    if(m){
      var comment=m[5]||'', source='', seen='';
      comment.split(';').forEach(function(part){
        var p=part.split('='), key=(p.shift()||'').trim().toLowerCase(), value=p.join('=').trim();
        if(key==='src' || key==='source') source=value;
        if(key==='seen') seen=value;
      });
      rows.push({ip:m[1],timeout:m[2],packets:m[3],bytes:m[4],seen:prettySeen(seen),source:source||comment||'-'});
      return;
    }

    /* Compatibiliteit met de oudere notatie met =-tekens. */
    var old=line.match(/^([0-9.\/]+)\s+timeout=?\s*([0-9]+)\s+packets=?\s*([0-9]+)\s+bytes=?\s*([0-9]+)(?:\s+seen=?\s*([^\s]+))?\s*(.*)$/i);
    if(old){
      rows.push({ip:old[1],timeout:old[2],packets:old[3],bytes:old[4],seen:prettySeen(old[5]||''),source:(old[6]||'-').replace(/^comment\s+"?|"?$/g,'')});
      return;
    }

    rows.push({raw:line});
  });
  return {meta:meta, rows:rows};
}
function parseFlows(txt){
  txt=splitCompactLines(txt); var lines=txt.split('\n').map(function(x){return x.trim()}).filter(Boolean);
  if(lines.length && /^Bytes\s+Source/.test(lines[0])) lines.shift();
  return lines.map(function(line){var m=line.match(/^(\d+)\s+([0-9.]+)\s+([0-9.]+)\s+(\d+)\s+(yes|no)\s+(yes|no)\s+(.*)$/); return m?{bytes:m[1],src:m[2],dst:m[3],port:m[4],cand:m[5],final:m[6],hint:m[7]}:{raw:line};});
}
function parseResolved(txt){
  txt=decodeText(txt); var rows=[], re=/(\d{1,3}(?:\.\d{1,3}){3})\s+([^\s]+)/g, m;
  while((m=re.exec(txt))!==null) rows.push({ip:m[1],host:m[2]});
  return rows;
}
function parseExcludeRanges(txt){
  txt=decodeText(txt); var meta=[], rows=[];
  var membersIdx=txt.indexOf('Members:'); var metaTxt=membersIdx>=0?txt.slice(0,membersIdx).trim():txt.trim(); var membersTxt=membersIdx>=0?txt.slice(membersIdx+8).trim():'';
  if(metaTxt){ meta=metaTxt.replace(/\s(?=(Name:|Type:|Revision:|Header:|Size in memory:|References:|Number of entries:))/g,'\n').split('\n').map(function(x){return x.trim()}).filter(Boolean);
  }
  if(membersTxt){
    var re=/(\d{1,3}(?:\.\d{1,3}){3}\/\d{1,2})\s+comment\s+"([^"]*)"/g, m;
    while((m=re.exec(membersTxt))!==null) rows.push({range:m[1],comment:(m[2]||'-')});
    if(!rows.length){membersTxt.split(/\n+/).forEach(function(line){line=line.trim(); var mm=line.match(/^(\d{1,3}(?:\.\d{1,3}){3}\/\d{1,2})(?:\s+comment\s+"([^"]*)")?/); if(mm) rows.push({range:mm[1],comment:(mm[2]||'-')});});}
  }
  return {meta:meta, rows:rows};
}
function parseLog(txt){
  txt=splitCompactLines(txt);
  return txt.split('\n').map(function(x){return x.trim()}).filter(Boolean).map(function(line){var m=line.match(/^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(.*)$/); return m?{ts:m[1],msg:m[2]}:{ts:'',msg:line};});
}
Object.assign(VPNIPC_I18N.nl,{diagnostic:'Diagnose',diagnosticIp:'Apparaat-IP (IPv4)',diagnosticStart:'Start 2 minuten',diagnosticSnapshot:'IPv4-momentopnamen',diagnosticProtocol:'Protocol',diagnosticInvalid:'Vul een geldig IPv4-adres in.'});
Object.assign(VPNIPC_I18N.en,{diagnostic:'Diagnostics',diagnosticIp:'Device IP (IPv4)',diagnosticStart:'Start 2 minutes',diagnosticSnapshot:'IPv4 snapshots',diagnosticProtocol:'Protocol',diagnosticInvalid:'Enter a valid IPv4 address.'});
Object.assign(VPNIPC_I18N.nl,{diagnosticDevices:'ASUS-apparaten',diagnosticManual:'Handmatig IP',diagnosticReload:'Apparaten vernieuwen',diagnosticLoading:'Apparaten ophalen...',diagnosticClientsFailed:'ASUS-apparatenlijst niet beschikbaar; handmatig IP blijft mogelijk.',diagnostic_idle:'Nog niet gestart',diagnostic_starting:'Wachten op bevestiging van de router...',diagnostic_active:'Meting actief',diagnostic_expired:'Meting afgerond',diagnostic_error:'Diagnose mislukt.',diagnosticEmpty:'Meting actief; geen IPv4-verbindingen gevonden voor dit apparaat.'});
Object.assign(VPNIPC_I18N.en,{diagnosticDevices:'ASUS devices',diagnosticManual:'Manual IP',diagnosticReload:'Refresh devices',diagnosticLoading:'Loading devices...',diagnosticClientsFailed:'ASUS client list unavailable; manual IP remains available.',diagnostic_idle:'Not started',diagnostic_starting:'Waiting for router confirmation...',diagnostic_active:'Measurement active',diagnostic_expired:'Measurement finished',diagnostic_error:'Diagnostics failed.',diagnosticEmpty:'Measurement active; no IPv4 connections found for this device.'});
Object.assign(VPNIPC_I18N.nl,{diagnostic_paused:'Gepauzeerd — resultaat bewaard',diagnostic_stopped:'Gestopt — resultaat bewaard',diagnosticPause:'Pauzeren',diagnosticResume:'Hervatten',diagnosticExport:'Exporteren',diagnosticTime:'Waargenomen op',diagnosticClear:'Resultaat wissen',diagnosticClearConfirm:'De bewaarde diagnose wissen?',diagnosticLimited:'Laatste 2000 waarnemingen; export bevat privé-verbindingsgegevens.'});
Object.assign(VPNIPC_I18N.en,{diagnostic_paused:'Paused — results retained',diagnostic_stopped:'Stopped — results retained',diagnosticPause:'Pause',diagnosticResume:'Resume',diagnosticExport:'Export',diagnosticTime:'Observed at',diagnosticClear:'Clear results',diagnosticClearConfirm:'Clear the retained diagnostics?',diagnosticLimited:'Last 2000 observations; export contains private connection metadata.'});
Object.assign(VPNIPC_I18N.nl,{keepScrollPosition:'Scrollpositie behouden'});
Object.assign(VPNIPC_I18N.en,{keepScrollPosition:'Keep scroll position'});
Object.assign(VPNIPC_I18N.nl,{diagnosticDomain:'Domein (DNS-aanwijzing)',diagnosticUnknown:'Onbekend',diagnosticMarker:'Zender / gebeurtenis',diagnosticMark:'Markeren',diagnosticRemaining:'Resterend',diagnosticDnsNote:'DNS-aanwijzingen zijn geen bewijs van de gebruikte dienst. Versleutelde of eerder gecachte DNS kan ontbreken.'});
Object.assign(VPNIPC_I18N.en,{diagnosticDomain:'Domain (DNS hint)',diagnosticUnknown:'Unknown',diagnosticMarker:'Channel / event',diagnosticMark:'Mark',diagnosticRemaining:'Remaining',diagnosticDnsNote:'DNS hints do not prove the service used. Encrypted or previously cached DNS may be absent.'});
function addDiagnosticMarker(){
  var label=byId('diagnosticMarker').value.trim().slice(0,80);if(!label)return;
  diagnosticHistory.push({time:new Date().toISOString(),line:'MARKER '+label});
  diagnosticHistory=diagnosticHistory.slice(-2000);byId('diagnosticMarker').value='';renderLiveTab();
}
function updateDiagnosticTimer(){
  var remaining=diagnosticState==='active'?Math.max(0,Math.ceil((diagnosticUntil-Date.now())/1000)):0;
  setText('diagnosticCountdown',diagnosticState==='active'?t('diagnosticRemaining')+': '+remaining+'s':'');
  var progress=byId('diagnosticProgress');if(progress){progress.hidden=diagnosticState!=='active';progress.value=120-remaining;}
}
function retainDiagnosticDns(ip){
  decodeText(dataCache.diagnostic_dns_text).split('\n').forEach(function(line){
    var p=line.split(/\s+/);if(p.length!==4||p[1]!==ip||!/^[0-9]+\.[0-9]+$/.test(p[0])||diagnosticDnsSeen[line])return;
    diagnosticDnsSeen[line]=true;
    if(p[3]!=='-'){
      var key=ip+'|'+p[3],names=diagnosticDomains[key]||[];
      if(names.indexOf(p[2])<0)names.push(p[2]);diagnosticDomains[key]=names.slice(-4);
    }
    diagnosticHistory.push({time:new Date(Number(p[0])*1000).toISOString(),line:'dns '+ip+' '+p[3]+' 53 '+(p[3]==='-'?'QUERY':'ANSWER')+' -',domain:p[2]});
  });
}
function retainDiagnosticSnapshot(){
  if(diagnosticState!=='active')return;
  var ip=byId('diagnosticIp').value.trim(),text=decodeText(dataCache.diagnostic_text);
  if(dataCache.diagnostic_target!==ip || dataCache.diagnostic_status!=='active')return;
  retainDiagnosticDns(ip);
  var key=String(dataCache.last_update||'')+'|'+text;
  if(key===diagnosticSnapshotKey)return;
  diagnosticSnapshotKey=key;
  var next={},time=new Date().toISOString();
  text.split('\n').filter(function(line){return line&&(/^(ERROR:|TRUNCATED)/.test(line)||line.split(/\s+/)[1]===ip);}).forEach(function(line){
    next[line]=true;
    if(!diagnosticPrevious[line])diagnosticHistory.push({time:time,line:line,domain:(diagnosticDomains[ip+'|'+line.split(/\s+/)[2]]||[]).join(', ')});
  });
  diagnosticPrevious=next;
  diagnosticHistory=diagnosticHistory.slice(-2000);
}
function pauseDiagnostic(){
  if(diagnosticBusy)return;
  if(diagnosticState==='active'){
    retainDiagnosticSnapshot();diagnosticState='paused';diagnosticUntil=0;diagnosticBusy=true;renderLiveTab();
    postRcEvent('vipcDstop').then(function(){loadStatus();}).catch(function(){diagnosticState='error';diagnosticError=t('routerActionFailed');renderLiveTab();}).finally(function(){diagnosticBusy=false;});
  }else if(diagnosticState==='paused')startDiagnostic();
}
function clearDiagnostic(){
  if(!window.confirm(t('diagnosticClearConfirm')))return;
  diagnosticHistory=[];diagnosticPrevious={};diagnosticSnapshotKey='';diagnosticDnsSeen={};diagnosticDomains={};renderLiveTab();
}
function exportDiagnostic(){
  retainDiagnosticSnapshot();
  var blob=new Blob([JSON.stringify({format:'vpn-ipcatcher-diagnostic-v1',exported_at:new Date().toISOString(),timestamps:'browser observation time; not connection start time',observations:diagnosticHistory},null,2)],{type:'application/json'});
  var url=URL.createObjectURL(blob),link=document.createElement('a');
  link.href=url;link.download='vpn-ipcatcher-diagnostic-'+new Date().toISOString().replace(/[:.]/g,'-')+'.json';
  document.body.appendChild(link);link.click();link.remove();setTimeout(function(){URL.revokeObjectURL(url);},1000);
}
function startDiagnostic(){
  var ip=byId('diagnosticIp').value.trim();
  var parts=ip.split('.');
  if(parts.length!==4 || !parts.every(function(p){return /^\d{1,3}$/.test(p)&&Number(p)<=255;})){showToast(t('diagnosticInvalid'));return;}
  ip=parts.map(function(p){return String(Number(p));}).join('.');byId('diagnosticIp').value=ip;
  if(diagnosticBusy || actionBusy)return;
  var nonce='d'+Date.now().toString(36)+Math.random().toString(36).slice(2,8);
  diagnosticState='starting';diagnosticError='';diagnosticBusy=true;diagnosticUntil=0;renderLiveTab();
  postRcEvent('vipcD'+nonce+'_'+ip).then(function(){return waitForActionResult(nonce,12);}).then(function(){
    diagnosticDnsSeen={};diagnosticDomains={};diagnosticPrevious={};diagnosticSnapshotKey='';
    diagnosticUntil=Date.now()+120000;diagnosticState='active';renderLiveTab();
  }).catch(function(err){diagnosticState='error';diagnosticError=String(err.message||err);renderLiveTab();}).finally(function(){diagnosticBusy=false;});
}
function refreshDiagnostic(start){
  if(diagnosticBusy || diagnosticState!=='active' || Date.now()>=diagnosticUntil || actionBusy)return;
  diagnosticBusy=true;
  postRcEvent(start?'vipcD'+byId('diagnosticIp').value.trim():'vipcE').then(function(){loadStatus();}).catch(function(){showToast(t('noConfirmation'));}).finally(function(){diagnosticBusy=false;});
}
function stopDiagnostic(){
  if(diagnosticBusy)return;
  retainDiagnosticSnapshot();diagnosticUntil=0;diagnosticState='stopped';renderLiveTab();
  return postRcEvent('vipcDstop').then(function(){loadStatus();}).catch(function(){diagnosticState='error';diagnosticError=t('routerActionFailed');renderLiveTab();});
}
function diagnosticDevices(data){
  var found={},result=[];
  if(!data || typeof data!=='object')return result;
  var keys=Array.isArray(data.maclist)?data.maclist:Object.keys(data);
  keys.forEach(function(key){var c=data[key];if(!c||typeof c!=='object'||String(c.isOnline)!=='1')return;
    var ip=String(c.ip||''),p=ip.split('.');
    if(p.length!==4||!p.every(function(v){return /^\d{1,3}$/.test(v)&&Number(v)<=255;})||found[ip])return;
    found[ip]=true;result.push({ip:ip,name:String(c.nickName||c.name||ip)});
  });
  return result.sort(function(a,b){return a.name.localeCompare(b.name);});
}
function loadDiagnosticClients(){
  if(diagnosticClientsBusy)return;
  diagnosticClientsBusy=true;setText('diagnosticClientsStatus',t('diagnosticLoading'));
  fetch('/appGet.cgi?hook=get_clientlist()', {credentials:'same-origin',cache:'no-store'}).then(function(r){if(!r.ok)throw new Error('HTTP '+r.status);return r.json();}).then(function(data){
    if(!data.get_clientlist||typeof data.get_clientlist!=='object')throw new Error('client list unavailable');
    var devices=diagnosticDevices(data.get_clientlist),select=byId('diagnosticDevice'),selected=select.value;
    select.innerHTML='<option value="">'+escapeHtml(t('diagnosticManual'))+'</option>'+devices.map(function(c){return '<option value="'+escapeHtml(c.ip)+'">'+escapeHtml(c.name+' - '+c.ip)+'</option>';}).join('');
    select.value=selected;setText('diagnosticClientsStatus',devices.length+' '+t('diagnosticDevices'));
  }).catch(function(){setText('diagnosticClientsStatus',t('diagnosticClientsFailed'));}).finally(function(){diagnosticClientsBusy=false;});
}
function chooseDiagnosticDevice(){
  var ip=byId('diagnosticDevice').value;if(ip)byId('diagnosticIp').value=ip;
  diagnosticUntil=0;diagnosticState='idle';renderLiveTab();
}
function filterLiveRows(rows){
  var query=(byId('liveSearch').value||'').trim().toLowerCase();
  var source=byId('flowSource').value, port=byId('flowPort').value, state=byId('flowState').value;
  var filtered=rows.filter(function(r){
    if(query && Object.keys(r).map(function(k){return String(r[k]);}).join(' ').toLowerCase().indexOf(query)<0) return false;
    if(currentTab!=='flows') return true;
    if(source && r.src!==source) return false;
    if(port && r.port!==port) return false;
    if(state==='final') return r.final==='yes';
    if(state==='candidate') return r.cand==='yes';
    if(state==='excluded') return /^excluded/.test(r.hint||'');
    if(state==='other') return r.final==='no' && r.cand==='no' && !/^excluded/.test(r.hint||'');
    return true;
  });
  setText('liveRowCount',filtered.length+' / '+rows.length+' '+t('filterRows'));
  return filtered;
}
function updateFlowOptions(id,values){
  var el=byId(id), selected=el.value;
  values=Array.from(new Set(values.filter(Boolean))).sort();
  if(selected && values.indexOf(selected)<0) values.push(selected);
  el.innerHTML='<option value="">'+escapeHtml(t('filterAll'))+'</option>'+values.map(function(v){return '<option value="'+escapeHtml(v)+'">'+escapeHtml(v)+'</option>';}).join('');
  el.value=selected;
}
function clearLiveFilters(){
  ['liveSearch','flowSource','flowPort','flowState'].forEach(function(id){byId(id).value='';});
  renderLiveTab();
}
function formatFlowBytes(bytes){
  var n=Number(bytes), units=['B','KB','MB','GB','TB'],i=0;
  if(!Number.isFinite(n)||n<0) return bytes;
  while(n>=1000 && i<units.length-1){n/=1000;i++;}
  return n.toLocaleString(vpnipcCurrentLanguage,{maximumFractionDigits:i?1:0})+' '+units[i];
}
function renderLiveTab(){
  if(!dataCache) return;
  var box=byId('liveOutput'), txt='';
  var oldScroll=box.querySelector?box.querySelector('.scroll'):null;
  if(renderedLiveTab&&oldScroll)liveScrollPositions[renderedLiveTab]={top:oldScroll.scrollTop,left:oldScroll.scrollLeft,outerLeft:box.scrollLeft};
  if(currentTab==='flows') txt=dataCache.flows_text;
  if(currentTab==='log') txt=dataCache.log_text;
  if(currentTab==='status') txt=dataCache.status_text;
  if(currentTab==='candidate') txt=dataCache.candidate_text;
  if(currentTab==='waiting') txt=dataCache.waiting_text;
  if(currentTab==='final') txt=dataCache.final_text;
  if(currentTab==='resolved') txt=dataCache.resolved_text;
  if(currentTab==='excludenets') txt=dataCache.exclude_net_text;
  var html='';
  var diagnostic=byId('diagnosticControls');if(diagnostic)diagnostic.hidden=currentTab!=='diagnostic';
  var liveFilters=byId('liveFilters');if(liveFilters)liveFilters.hidden=currentTab==='diagnostic';
  var flowControls=byId('flowControls');if(flowControls)flowControls.hidden=currentTab!=='flows';
  if(currentTab==='diagnostic'){
    retainDiagnosticSnapshot();
    if(diagnosticState==='active'&&(Date.now()>=diagnosticUntil||dataCache.diagnostic_status==='expired'))diagnosticState='expired';
    var rows=diagnosticHistory.slice().reverse().map(function(entry){var p=entry.line.split(/\s+/);return p.length===6&&!/^MARKER /.test(entry.line)?td(new Date(entry.time).toLocaleString())+td(p[0])+td(p[1],'mono')+td(p[2],'mono')+td(entry.domain||t('diagnosticUnknown'))+td(p[3])+td(p[4])+td(formatFlowBytes(p[5])):td(new Date(entry.time).toLocaleString())+'<td colspan="7">'+escapeHtml(entry.line)+'</td>';});
    html=renderTable([t('diagnosticTime'),t('diagnosticProtocol'),t('source'),t('destination'),t('diagnosticDomain'),t('port'),t('status'),t('trafficVolume')],rows);
    setText('diagnosticPauseButton',t(diagnosticState==='paused'?'diagnosticResume':'diagnosticPause'));
    var phase=dataCache.diagnostic_status==='error'&&diagnosticState==='active'?'error':diagnosticState;
    var message=t('diagnostic_'+phase)+(phase==='error'&&diagnosticError?' '+diagnosticError:'');
    setText('diagnosticState',message);
    updateDiagnosticTimer();
    if(!rows.length)html='<div class="muted">'+escapeHtml(phase==='active'?t('diagnosticEmpty'):message)+'</div>';
  } else if(currentTab==='flows'){
    var flows=parseFlows(txt);
    updateFlowOptions('flowSource',flows.map(function(r){return r.src;}));
    updateFlowOptions('flowPort',flows.map(function(r){return r.port;}));
    var rows=filterLiveRows(flows).map(function(r){return r.raw?'<td colspan="7" class="mono">'+escapeHtml(r.raw)+'</td>':'<td class="mono" title="'+escapeHtml(r.bytes)+' B">'+escapeHtml(formatFlowBytes(r.bytes))+'</td>'+td(r.src,'mono')+td(r.dst,'mono')+td(r.port,'mono')+td(r.cand)+td(r.final)+td(r.hint);});
    html=renderTable([t('trafficVolume'),t('source'),t('destination'),t('port'),t('cand'),t('final'),t('hint')], rows);
  } else if(currentTab==='log'){
    var rows=filterLiveRows(parseLog(txt)).map(function(r){return td(r.ts,'mono')+td(r.msg);});
    html=renderTable([t('timestamp'),t('message')], rows);
  } else if(currentTab==='status'){
    var rows=filterLiveRows(parseKeyValueStatus(txt)).map(function(r){return r.section?'<td colspan="2"><strong>'+escapeHtml(r.label)+'</strong></td>':td(r.key)+td(r.value);});
    html=renderTable([t('field'),t('value')], rows);
  } else if(currentTab==='candidate' || currentTab==='waiting' || currentTab==='final'){
    var dump=parseIpsetDump(txt), meta=dump.meta.length?'<pre>'+escapeHtml(dump.meta.join('\n'))+'</pre>':'';
    var rows=filterLiveRows(dump.rows).map(function(r){return r.raw?'<td colspan="6" class="mono">'+escapeHtml(r.raw)+'</td>':td(r.ip,'mono')+td(r.timeout,'mono')+td(r.packets,'mono')+td(r.bytes,'mono')+td(r.seen,'mono')+td(r.source);});
    html='<div class="ipsetDump">'+meta+renderTable(['IP',t('timeout'),t('packets'),t('bytes'),t('seen'),t('source')], rows)+'</div>';
  } else if(currentTab==='resolved'){
    var rows=filterLiveRows(parseResolved(txt)).map(function(r){return td(r.ip,'mono')+td(r.host);});
    html=renderTable(['IP',t('hostnameDomain')], rows);
  } else if(currentTab==='excludenets'){
    var dump=parseExcludeRanges(txt), meta=dump.meta.length?'<pre>'+escapeHtml(dump.meta.join('\n'))+'</pre>':'';
    var rows=filterLiveRows(dump.rows).map(function(r){return td(r.range,'mono')+td(r.comment);});
    html=meta+renderTable([t('range'),t('comment')], rows);
  }
  var nextHtml=html||'<div class="muted">'+escapeHtml(t('noData'))+'</div>';
  if(box.innerHTML!==nextHtml)box.innerHTML=nextHtml;
  var newScroll=box.querySelector?box.querySelector('.scroll'):null;
  var keep=byId('liveKeepPosition'),position=liveScrollPositions[currentTab];
  if(newScroll){
    if(!keep||keep.checked){
      newScroll.scrollTop=position?position.top:0;newScroll.scrollLeft=position?position.left:0;box.scrollLeft=position?position.outerLeft:0;
    }else{
      newScroll.scrollTop=currentTab==='log'?newScroll.scrollHeight:0;
    }
  }
  renderedLiveTab=currentTab;
}
function updateOverview(d){
  setText('addonVersion',d.version||'-');
  var connection=d.vpn_connection||'', match=connection.match(/^(ovpnc|wgc)([1-5])$/);
  setText('selectedVpn',match?(match[1]==='ovpnc'?'OpenVPN ':'WireGuard ')+match[2]:'-');
  setText('selectedList',d.ipset_name||'');
  badge(d.engine); setText('lastUpdate',d.last_update); setText('enginePid',d.engine_pid); setText('tcpdumpCount',d.tcpdump_count); setText('candidateCount',d.candidate_count); setText('finalCount',d.final_count); setText('resolvedCount',d.resolved_count); setText('excludeNetCount',d.exclude_net_count); setText('excludeNetSet',d.exclude_net_set); setText('ipsetName',d.ipset_name);
  setText('overviewEngineState', d.engine==='running' ? t('serviceRunning') : t('serviceStopped'));
    setText('overviewCapture', 'tcpdump: '+(d.tcpdump_count||'-')+' - '+t('updated')+': '+(d.last_update||'-'));
  setText('overviewSourceIps', (d.config && d.config.SOURCE_IPS) ? d.config.SOURCE_IPS : t('allDevices'));
}
function presetState(item){
  var doms=getWords(byId('cfg_EXCLUDE_DOMAINS').value);
  var ips=getWords(byId('cfg_EXCLUDE_IPS').value).concat(protectedPresetIps||[]);
  var nets=getWords(byId('cfg_EXCLUDE_NETS').value);
  var need=[item.domains||[], item.ips||[], item.nets||[]], have=[doms,ips,nets];
  var all=true, any=false, hasNeed=false;
  for(var i=0;i<need.length;i++){
    if(!need[i].length) continue;
    hasNeed=true;
    var set={}, allThis=true, anyThis=false;
    have[i].forEach(function(x){set[x]=1;});
    need[i].forEach(function(x){if(set[x]) anyThis=true; else allThis=false;});
    if(anyThis) any=true;
    if(!allThis) all=false;
  }
  if(hasNeed && all) return 'ON';
  if(any) return 'PART';
  return 'OFF';
}
function applyPresetToConfig(item, mode){
  var domEl=byId('cfg_EXCLUDE_DOMAINS'), ipEl=byId('cfg_EXCLUDE_IPS'), netEl=byId('cfg_EXCLUDE_NETS');
  if(mode==='add'){
    domEl.value=mergeUnique(domEl.value,item.domains||[]);
    ipEl.value=mergeUnique(ipEl.value,item.ips||[]);
    netEl.value=mergeUnique(netEl.value,item.nets||[]);
  } else {
    domEl.value=removeWords(domEl.value,item.domains||[]);
    ipEl.value=removeWords(ipEl.value,item.ips||[]);
    netEl.value=removeWords(netEl.value,item.nets||[]);
  }
  dirty=true;
  pendingPresetKeys[item.key]=true;
  updateExclusionPreview();
  renderPresets();
  showToast((mode==='add'?t('addedConfig'):t('removedConfig'))+vpnipcPresetLabel(item)+t('rememberSave'));
}
function findPreset(key){
  for(var c=0;c<PRESET_CATEGORIES.length;c++){
    var items=PRESET_CATEGORIES[c].items||[];
    for(var i=0;i<items.length;i++) if(items[i].key===key) return items[i];
  }
  return null;
}
function togglePresetDirect(el){
  var item=findPreset(el.getAttribute('data-key'));
  if(item) applyPresetToConfig(item, el.checked ? 'add' : 'remove');
}

function vpnipcCategoryName(cat){var key=VPNIPC_CATEGORY_KEYS[cat.name||'']; return key?t(key):(cat.name||'Presets');}
function vpnipcCategoryNote(cat){var key=VPNIPC_CATEGORY_NOTE_KEYS[cat.name||'']; return key?t(key):(cat.note||'');}
function vpnipcPresetLabel(item){return vpnipcCurrentLanguage==='nl'?(VPNIPC_PRESET_LABEL_NL[item.key]||item.label):(item.label||item.key);}

function renderPresets(){
  setText('pendingChanges',dirty?t('unsaved'):'');
  var pendingBar=byId('pendingBar');if(pendingBar)pendingBar.hidden=!dirty;
  var wrap=byId('presetWrap');
  if(!wrap) return;
  if(!PRESET_CATEGORIES.length){wrap.innerHTML='<div class="muted">'+escapeHtml(t('presetsLoading'))+'</div>'; return;}
  var html='';
  PRESET_CATEGORIES.forEach(function(cat){
    html+='<div class="presetCard"><h4>'+escapeHtml(vpnipcCategoryName(cat))+'</h4>';
    var catNote=vpnipcCategoryNote(cat); if(catNote) html+='<div class="presetMeta" style="margin-bottom:6px">'+escapeHtml(catNote)+'</div>';
    (cat.items||[]).forEach(function(item){
      var state=presetState(item), checked=state==='ON', pending=!!pendingPresetKeys[item.key], shownState=t(state==='ON'?'presetOn':state==='PART'?'presetPart':'presetOff')+(pending?' *':''), cls=pending?'statusPart':(state==='ON'?'statusOn':(state==='PART'?'statusPart':'statusOff'));
      var meta=[], detail=[];
      if((item.domains||[]).length) meta.push('<span class="pill">'+item.domains.length+' '+t('domainsCount')+'</span>');
      if((item.ips||[]).length) meta.push('<span class="pill">'+item.ips.length+' IPs</span>');
      if((item.nets||[]).length) meta.push('<span class="pill">'+item.nets.length+' '+t('rangesCount')+'</span>');
      if((item.domains||[]).length) detail.push(t('detailsDomains')+': '+item.domains.join(', '));
      if((item.ips||[]).length) detail.push('IPs: '+item.ips.join(', '));
      if((item.nets||[]).length) detail.push(t('detailsRanges')+': '+item.nets.join(', '));
      html+='<div class="presetItem" data-search="'+escapeHtml(((vpnipcPresetLabel(item)||'')+' '+detail.join(' ')).toLowerCase())+'">';
      html+='<input type="checkbox" class="presetCheck" aria-label="'+escapeHtml(vpnipcPresetLabel(item))+'" data-key="'+escapeHtml(item.key)+'" data-partial="'+(state==='PART'?'yes':'no')+'" '+(checked?'checked':'')+' onchange="togglePresetDirect(this)">';
      html+='<div style="flex:1">';
      html+='<div><strong>'+escapeHtml(vpnipcPresetLabel(item))+'</strong> - <span class="'+cls+'">'+shownState+'</span></div>';
      html+='<div class="presetMeta">'+meta.join(' ')+'</div>';
      html+='<details><summary>'+escapeHtml(t('details'))+'</summary><div class="presetMeta">'+escapeHtml(detail.join(' | '))+'</div></details>';
      html+='</div></div>';
    });
    html+='</div>';
  });
  wrap.innerHTML=html;
  wrap.querySelectorAll('.presetCheck[data-partial="yes"]').forEach(function(el){el.indeterminate=true;});
  filterPresets();
}
function filterPresets(){
  var q=(byId('presetSearch').value||'').toLowerCase().trim();
  document.querySelectorAll('.vpn_ipcatcher_dashboard .presetItem').forEach(function(item){
    var text=item.getAttribute('data-search')||'';
    item.style.display=(!q || text.indexOf(q)>=0)?'':'none';
  });
}
function selectAllVisible(val){
  var checks=Array.prototype.slice.call(document.querySelectorAll('.vpn_ipcatcher_dashboard .presetCheck'));
  checks.forEach(function(ch){
    var row=ch.closest('.presetItem');
    if(row && row.style.display !== 'none' && ch.checked !== val){
      ch.checked = val;
      togglePresetDirect(ch);
    }
  });
}
function loadPresets(){
  return fetch('/user/vpn_ipcatcher_presets.json?ts='+Date.now(),{cache:'no-store'})
    .then(function(r){if(!r.ok) throw new Error('HTTP '+r.status); return r.json();})
    .then(function(p){
      PRESET_CATEGORIES=Array.isArray(p.categories)?p.categories:[];
      if(Array.isArray(p.protected_ips)) protectedPresetIps=p.protected_ips;
      renderPresets();
    })
    .catch(function(err){
      var wrap=byId('presetWrap');
      if(wrap) wrap.innerHTML='<pre>'+escapeHtml(t('presetLoadFailed'))+escapeHtml(err)+'</pre>';
    });
}
function updateExclusionPreview(){
  setText('previewDomains', byId('cfg_EXCLUDE_DOMAINS').value || '-');
  setText('previewIps', byId('cfg_EXCLUDE_IPS').value || '-');
  setText('previewNets', byId('cfg_EXCLUDE_NETS').value || '-');
}
function organizeSettings(){
  var grid=document.querySelector('#page_config .formgrid');
  if(!grid) return;
  var groups=[['devices',['INTERFACES','IPSET_NAME','SOURCE_IPS','PORTS']],['learning',['PROMOTE_MODE','STREAM_FLOW_SCAN','STREAM_FLOW_TARGET']],['advanced',[]],['exclusions',['EXCLUDE_IPS','EXCLUDE_NETS','EXCLUDE_DOMAINS']]];
  var fields={};
  Array.prototype.slice.call(grid.children).forEach(function(el){if(el.id&&el.id.indexOf('cfg_')===0)fields[el.id.slice(4)]=[el.previousElementSibling,el];});
  groups[2][1]=Object.keys(fields).filter(function(k){return !groups.some(function(g){return g[1].indexOf(k)>=0;});});
  groups.forEach(function(group){
    var holder=document.createElement(group[0]==='advanced'?'details':'fieldset');
    holder.className='settingsGroup';
    var heading=document.createElement(group[0]==='advanced'?'summary':'legend');
    heading.setAttribute('data-i18n',group[0]); heading.textContent=t(group[0]); holder.appendChild(heading);
    var inner=document.createElement('div');inner.className='formgrid';holder.appendChild(inner);
    group[1].forEach(function(k){if(fields[k])fields[k].forEach(function(el){inner.appendChild(el);});});
    grid.parentNode.insertBefore(holder,grid);
  });
  grid.remove();
  document.querySelectorAll('#page_config input').forEach(function(el){
    if(/PROMOTE_EVERY|MIN_AGE|MIN_BYTES|TIMEOUT|SCAN_EVERY|MIN_DELTA|RESOLVE_EVERY|RETRY_DELAY/.test(el.id)){el.type='number';el.min='0';el.step='1';}
  });
}
function loadStatus(){
  fetch('/user/vpn_ipcatcher_status.json?ts='+Date.now(), {cache:'no-store'})
    .then(function(r){return r.json()})
    .then(function(d){applyStatusData(d);})
    .catch(function(err){ byId('liveOutput').innerHTML='<pre>'+escapeHtml(t('jsonFailed'))+escapeHtml(err)+'</pre>'; });
}

window.addEventListener('load', function(){
  organizeSettings();
  vpnipcInitLanguage();
  document.querySelectorAll('.vpn_ipcatcher_dashboard [id^="cfg_"]').forEach(function(e){ e.addEventListener('input', function(){ dirty=true; updateExclusionPreview(); renderPresets(); }); });
  setPage('overview'); setTab('flows'); loadPresets(); loadStatus(); setInterval(function(){ if(!actionBusy){if(currentPage==='live'&&currentTab==='diagnostic')refreshDiagnostic();loadStatus();} }, 5000);
  setInterval(function(){if(currentPage==='live'&&currentTab==='diagnostic')updateDiagnosticTimer();},1000);
});
</script>
</head>

<body class="bg" onload="initial();" onunload="unload_body();">
<input type="hidden" id="routerPreferredLang" value="<% nvram_get("preferred_lang"); %>">

<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

<table class="content" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td width="17">&nbsp;</td>
    
    <td valign="top" width="202">
      <div id="mainMenu"></div>
      <div id="subMenu"></div>
    </td>
    
    <td valign="top">
      <div id="tabMenu" class="submenuBlock"></div>
      <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
        <tr>
          <td align="left" valign="top">
            
            <div class="vpn_ipcatcher_dashboard">
              <div class="wrap">
                <div class="topbar">
                  <div class="languageRow">
                    <label for="vpnipcLanguage" data-i18n="language">Taal</label>
                    <select id="vpnipcLanguage" onchange="vpnipcChangeLanguage(this.value)">
                      <option value="auto" data-i18n="autoRouter">Automatisch (router)</option>
                      <option value="nl">Nederlands</option>
                      <option value="en">English</option>
                    </select>
                  </div>
                  <div class="title" data-i18n="title">VPN IP Catcher-dashboard</div>
                  <div class="subtitle" data-i18n="subtitle">ASUS Merlin WebUI - stabiele runtime en betere uitsluitingen/presets</div>
                  <div class="sessionMeta"><span><span data-i18n="version">Versie</span> <strong id="addonVersion">-</strong></span><span>VPN: <strong id="selectedVpn">-</strong></span><span class="mono" id="selectedList"></span></div>
                </div>

                <form method="post" id="vpnipc_form" name="vpnipc_form" action="/start_apply.htm" target="vpnipc_hidden_frame" onsubmit="return false;">
                  <input type="hidden" name="current_page" value="__VPNIPC_PAGE__">
                  <input type="hidden" name="next_page" value="__VPNIPC_PAGE__">
                  <input type="hidden" name="action_mode" value="apply">
                  <input type="hidden" name="action_script" id="action_script" value="restart_vpnipcatcher">
                  <input type="hidden" name="action_wait" value="2">
                  <input type="hidden" name="amng_custom" id="amng_custom" value="">
                </form>
                <iframe name="vpnipc_hidden_frame" id="vpnipc_hidden_frame" style="display:none;width:0;height:0;border:0"></iframe>

                <div class="grid">
                  <div class="card"><h3 data-i18n="engine">Engine</h3><div><span id="engineBadge" class="badge warn" data-i18n="loading">LADEN</span></div><div class="muted">PID: <span id="enginePid">-</span></div></div>
                  <div class="card"><h3 data-i18n="finalIps">Definitieve IP’s</h3><div class="big" id="finalCount">-</div><div class="muted" id="ipsetName">-</div></div>
                  <div class="card"><h3 data-i18n="candidateIps">Kandidaat-IP’s</h3><div class="big" id="candidateCount">-</div><div class="muted" data-i18n="candidateHint">tijdelijke leerset</div></div>
                  <div class="card"><h3 data-i18n="excludeCache">Uitsluitcache</h3><div class="big" id="resolvedCount">-</div><div class="muted" data-i18n="excludeCacheHint">tijdelijk opgeloste domein-IP’s</div></div>
                  <div class="card"><h3 data-i18n="excludeRanges">Uitsluitbereiken</h3><div class="big" id="excludeNetCount">-</div><div class="muted" id="excludeNetSet" data-default-i18n="fixedRanges">vaste CIDR-bereiken</div></div>
                </div>
                <div class="muted" style="margin:-4px 0 8px 2px">tcpdump: <span id="tcpdumpCount">-</span> - <span data-i18n="updated">bijgewerkt</span>: <span id="lastUpdate">-</span></div>

                <div class="panel">
                  <div class="panel-title"><span data-i18n="actions">Acties</span> <span id="toast" class="muted"></span></div>
                  <div class="panel-body actions">
                    <button type="button" class="btn green" onclick="applyAction('start')" data-i18n="start">Start</button>
                    <button type="button" class="btn red" onclick="applyAction('stop')" data-i18n="stop">Stop</button>
                    <button type="button" class="btn orange" onclick="applyAction('restart')" data-i18n="restart">Herstarten</button>
                    <button type="button" class="btn blue" onclick="applyAction('publish')" data-i18n="refreshStatus">Status vernieuwen</button>
                  </div>
                  <details class="maintenance"><summary data-i18n="maintenance">Onderhoud</summary><div class="actions">
                    <button type="button" class="btn" onclick="applyAction('resolve_excludes')" data-i18n="resolveExcludes">Uitsluitingen oplossen</button>
                    <button type="button" class="btn" onclick="applyAction('safe_excludes')" data-i18n="safeBaseExcludes">Veilige basisuitsluitingen</button>
                    <button type="button" class="btn orange" onclick="applyAction('repair_excludes')" data-i18n="repairSafeExcludes">Veilige uitsluitingen herstellen</button>
                    <button type="button" class="btn" onclick="applyAction('clean_excluded')" data-i18n="cleanExcludedIps">Uitgesloten IP’s opruimen</button>
                    <button type="button" class="btn" onclick="applyAction('clear_log')" data-i18n="clearLog">Log wissen</button>
                  </div></details>
                </div>

                <div class="layoutTabs">
                  <button type="button" class="layoutTab active" id="pageTab_overview" onclick="setPage('overview')" data-i18n="overview">Overview</button>
                  <button type="button" class="layoutTab" id="pageTab_live" onclick="setPage('live')" data-i18n="liveView">Live view</button>
                  <button type="button" class="layoutTab" id="pageTab_config" onclick="setPage('config')" data-i18n="config">Config</button>
                  <button type="button" class="layoutTab" id="pageTab_exclusions" onclick="setPage('exclusions')" data-i18n="exclusions">Exclusions</button>
                  <button type="button" class="layoutTab" id="pageTab_presets" onclick="setPage('presets')" data-i18n="presetLists">Preset lists</button>
                </div>

                <div id="pendingBar" class="actions saveBar" hidden><span id="pendingChanges"></span><button type="button" class="btn blue" onclick="applyAction('save_config_restart')" data-i18n="saveRestart">Opslaan + herstarten</button></div>
                <div class="page active" id="page_overview">
                  <div class="split">
                    <div class="panel">
                      <div class="panel-title" data-i18n="overview">Overzicht</div>
                      <div class="panel-body">
                        <table class="data"><tbody>
                          <tr><th data-i18n="engine">Engine</th><td id="overviewEngineState">-</td></tr>
                          <tr><th data-i18n="capture">Verkeer vastleggen</th><td id="overviewCapture">-</td></tr>
                          <tr><th data-i18n="sourceIps">Bron-IP’s</th><td id="overviewSourceIps">-</td></tr>
                          <tr><th data-i18n="tip">Tip</th><td data-i18n-html="overviewTip"></td></tr>
                        </tbody></table>
                      </div>
                    </div>
                    <div class="panel">
                      <div class="panel-title" data-i18n="quickLinks">Snelkoppelingen</div>
                      <div class="panel-body actions">
                        <button type="button" class="btn blue" onclick="setPage('live');setTab('flows')" data-i18n="openLiveFlows">Open live flows</button>
                        <button type="button" class="btn blue" onclick="setPage('live');setTab('status')" data-i18n="openStatus">Open status</button>
                        <button type="button" class="btn blue" onclick="setPage('presets')" data-i18n="openPresetLists">Open preset lists</button>
                        <button type="button" class="btn blue" onclick="setPage('config')" data-i18n="openConfig">Open config</button>
                        <button type="button" class="btn blue" onclick="setPage('exclusions')" data-i18n="openExclusions">Open exclusions</button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="page" id="page_live">
                  <div class="panel">
                    <div class="panel-title" data-i18n="liveView">Liveweergave</div>
                    <div class="panel-body">
                      <div class="tabs">
                        <button type="button" id="tab_flows" class="tab active" onclick="setTab('flows')" data-i18n="liveFlows">Live flows</button>
                        <button type="button" id="tab_diagnostic" class="tab" onclick="setTab('diagnostic')" data-i18n="diagnostic">Diagnose</button>
                        <button type="button" id="tab_log" class="tab" onclick="setTab('log')" data-i18n="log">Log</button>
                        <button type="button" id="tab_status" class="tab" onclick="setTab('status')" data-i18n="status">Status</button>
                        <button type="button" id="tab_candidate" class="tab" onclick="setTab('candidate')" data-i18n="candidate">Candidate</button>
                        <button type="button" id="tab_waiting" class="tab" onclick="setTab('waiting')" data-i18n="waiting">Wachtlijst</button>
                        <button type="button" id="tab_final" class="tab" onclick="setTab('final')" data-i18n="final">Final</button>
                        <button type="button" id="tab_resolved" class="tab" onclick="setTab('resolved')" data-i18n="resolvedIps">Resolved IPs</button>
                        <button type="button" id="tab_excludenets" class="tab" onclick="setTab('excludenets')" data-i18n="excludeRanges">Exclude ranges</button>
                      </div>
                      <div id="diagnosticControls" class="liveFilters" hidden>
                        <label><span data-i18n="diagnosticDevices">ASUS-apparaten</span><select id="diagnosticDevice" onchange="chooseDiagnosticDevice()"><option value="" data-i18n="diagnosticManual">Handmatig IP</option></select></label>
                        <button type="button" class="btn" onclick="loadDiagnosticClients()" data-i18n="diagnosticReload">Apparaten vernieuwen</button>
                        <span id="diagnosticClientsStatus" class="muted"></span>
                        <label><span data-i18n="diagnosticIp">Apparaat-IP (IPv4)</span><input id="diagnosticIp" inputmode="decimal" placeholder="192.0.2.10" oninput="diagnosticUntil=0;diagnosticState='idle';renderLiveTab()"></label>
                        <button type="button" class="btn blue" onclick="startDiagnostic()" data-i18n="diagnosticStart">Start 2 minuten</button>
                        <button type="button" class="btn" onclick="stopDiagnostic()" data-i18n="stop">Stop</button>
                        <button type="button" id="diagnosticPauseButton" class="btn" onclick="pauseDiagnostic()" data-i18n="diagnosticPause">Pauzeren</button>
                        <button type="button" class="btn" onclick="exportDiagnostic()" data-i18n="diagnosticExport">Exporteren</button>
                        <button type="button" class="btn" onclick="clearDiagnostic()" data-i18n="diagnosticClear">Resultaat wissen</button>
                        <span class="muted" data-i18n="diagnosticSnapshot">IPv4-momentopnamen</span>
                        <span id="diagnosticState" class="muted" role="status"></span>
                        <span id="diagnosticCountdown" class="muted"></span><progress id="diagnosticProgress" max="120" value="0" hidden></progress>
                        <label><span data-i18n="diagnosticMarker">Zender / gebeurtenis</span><input id="diagnosticMarker" maxlength="80"></label>
                        <button type="button" class="btn" onclick="addDiagnosticMarker()" data-i18n="diagnosticMark">Markeren</button>
                        <span class="muted" data-i18n="diagnosticDnsNote">DNS-aanwijzingen zijn geen bewijs van de gebruikte dienst. Versleutelde of eerder gecachte DNS kan ontbreken.</span>
                        <span class="muted" data-i18n="diagnosticLimited">Laatste 2000 waarnemingen; export bevat privé-verbindingsgegevens.</span>
                      </div>
                      <div id="liveFilters" class="liveFilters">
                        <label><span data-i18n="filterSearch">Zoeken</span><input type="search" id="liveSearch" oninput="renderLiveTab()"></label>
                        <div id="flowControls">
                          <label><span data-i18n="filterSource">Bronapparaat</span><select id="flowSource" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option></select></label>
                          <label><span data-i18n="filterPort">Poort</span><select id="flowPort" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option></select></label>
                          <label><span data-i18n="filterState">Lijststatus</span><select id="flowState" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option><option value="final" data-i18n="filterFinal">Definitieve lijst</option><option value="candidate" data-i18n="filterCandidate">Kandidaat</option><option value="excluded" data-i18n="filterExcluded">Uitgesloten</option><option value="other" data-i18n="filterOther">Overige</option></select></label>
                        </div>
                        <button type="button" class="btn" onclick="clearLiveFilters()" data-i18n="filterClear">Filters wissen</button>
                        <span id="liveRowCount" class="muted" aria-live="polite"></span>
                      </div>
                      <label><input type="checkbox" id="liveKeepPosition" checked onchange="renderLiveTab()"> <span data-i18n="keepScrollPosition">Scrollpositie behouden</span></label>
                      <div id="liveOutput"></div>
                    </div>
                  </div>
                </div>

                <div class="page" id="page_config">
                  <div class="panel">
                    <div class="panel-title" data-i18n="configuration">Configuratie</div>
                    <div class="panel-body">
                      <div class="note" data-i18n="configNote">Wijzigingen worden opgeslagen in /jffs/scripts/vpn_ipcatcher.conf.</div>
                      <div class="formgrid">
                        <label data-i18n="interfaces">Interfaces</label><input id="cfg_INTERFACES" placeholder="br0">
                        <label data-i18n="ipsetName">IPSet name</label><input id="cfg_IPSET_NAME" readonly placeholder="DVR-StreamsVPNSW-v4">
                        <label data-i18n="ports">Ports</label><input id="cfg_PORTS" placeholder="80,443">
                        <label data-i18n="promoteMode">Promote mode</label><select id="cfg_PROMOTE_MODE"><option value="auto" data-i18n="auto">automatisch</option><option value="age" data-i18n="age">leeftijd</option><option value="bytes">bytes</option><option value="immediate" data-i18n="immediate">direct</option></select>
                        <label data-i18n="promoteInterval">Promote interval</label><input id="cfg_PROMOTE_EVERY" placeholder="15">
                        <label data-i18n="minAge">Min age</label><input id="cfg_MIN_AGE" placeholder="30">
                        <label data-i18n="minBytes">Min bytes</label><input id="cfg_MIN_BYTES" placeholder="3000000">
                        <label data-i18n="candidateTimeout">Candidate timeout</label><input id="cfg_CANDIDATE_TIMEOUT" placeholder="600">
                        <label data-i18n="finalTimeout">Final timeout</label><input id="cfg_FINAL_TIMEOUT" placeholder="7200">
                        <label data-i18n="streamFlowScan">Stream flow scan</label><select id="cfg_STREAM_FLOW_SCAN"><option value="yes" data-i18n="yes">ja</option><option value="no" data-i18n="no">nee</option></select>
                        <label data-i18n="sourceIpsLabel">Source IPs</label><input id="cfg_SOURCE_IPS" data-i18n-placeholder="emptyAllDevices" placeholder="leeg = alle apparaten">
                        <label data-i18n="streamScanInterval">Stream scan interval</label><input id="cfg_STREAM_SCAN_EVERY" placeholder="5">
                        <label data-i18n="streamMinBytes">Stream min bytes</label><input id="cfg_STREAM_MIN_BYTES" placeholder="3000000">
                        <label data-i18n="streamMinDelta">Stream min delta</label><input id="cfg_STREAM_MIN_DELTA" placeholder="750000">
                        <label data-i18n="requireGrowth">Require traffic growth</label><select id="cfg_STREAM_REQUIRE_GROWTH"><option value="yes" data-i18n="yes">ja</option><option value="no" data-i18n="no">nee</option></select>
                        <label data-i18n="streamTarget">Stream target</label><select id="cfg_STREAM_FLOW_TARGET"><option value="candidate" data-i18n="candidateValue">kandidaat</option><option value="final" data-i18n="finalValue">definitief</option></select>
                        <label data-i18n="excludeResolver">Exclude resolver</label><select id="cfg_EXCLUDE_RESOLVE_CACHE"><option value="yes" data-i18n="yes">ja</option><option value="no" data-i18n="no">nee</option></select>
                        <label data-i18n="resolverInterval">Resolver interval</label><input id="cfg_EXCLUDE_RESOLVE_EVERY" placeholder="3600">
                        <label data-i18n="reverseDnsCheck">Reverse DNS check</label><select id="cfg_REVERSE_DNS_CHECK"><option value="no" data-i18n="no">nee</option><option value="yes" data-i18n="yes">ja</option></select>
                        <label data-i18n="genericHostScan">Generic host scan</label><select id="cfg_CAPTURE_GENERIC_HOSTNAMES"><option value="no" data-i18n="no">nee</option><option value="yes" data-i18n="yes">ja</option></select>
                        <label data-i18n="externalDns">External DNS</label><select id="cfg_ALLOW_EXTERNAL_DNS"><option value="no" data-i18n="no">nee</option><option value="yes" data-i18n="yes">ja</option></select>
                        <label data-i18n="externalDnsServer">External DNS server</label><input id="cfg_EXTERNAL_DNS_SERVER" data-i18n-placeholder="empty" placeholder="leeg">
                        <label data-i18n="retryDelay">Retry delay</label><input id="cfg_RETRY_DELAY" placeholder="20">
                        <label data-i18n="maxRetryDelay">Max retry delay</label><input id="cfg_MAX_RETRY_DELAY" placeholder="60">
                        <label data-i18n="excludeIps">Exclude IPs</label><textarea id="cfg_EXCLUDE_IPS"></textarea>
                        <label data-i18n="excludeNets">Exclude nets/ranges</label><textarea id="cfg_EXCLUDE_NETS"></textarea>
                        <label data-i18n="excludeDomains">Exclude domains</label><textarea id="cfg_EXCLUDE_DOMAINS"></textarea>
                      </div>
                      <div class="actions saveBar" style="margin-top:12px">
                        <button type="button" class="btn blue" onclick="applyAction('save_config')" data-i18n="saveConfig">Save config</button>
                        <button type="button" class="btn orange" onclick="applyAction('save_config_restart')" data-i18n="saveRestart">Save + Restart</button>
                        <button type="button" class="btn" onclick="discardLocalChanges()" data-i18n="reloadConfig">Reload from config</button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="page" id="page_exclusions">
                  <div class="split">
                    <div class="panel">
                      <div class="panel-title" data-i18n="currentConfigExclusions">Huidige configuratie-uitsluitingen</div>
                      <div class="panel-body">
                        <table class="data"><tbody>
                          <tr><th data-i18n="domains">Domeinen</th><td><div class="mono previewList" id="previewDomains">-</div></td></tr>
                          <tr><th data-i18n="ips">IP’s</th><td><div class="mono previewList" id="previewIps">-</div></td></tr>
                          <tr><th data-i18n="ranges">Bereiken</th><td><div class="mono previewList" id="previewNets">-</div></td></tr>
                        </tbody></table>
                      </div>
                    </div>
                    <div class="panel">
                      <div class="panel-title" data-i18n="notes">Toelichting</div>
                      <div class="panel-body">
                        <div class="note" data-i18n-html="resolvedNote"></div>
                        <div class="note" data-i18n-html="configFieldsNote"></div>
                        <div class="actions">
                          <button type="button" class="btn blue" onclick="setPage('presets')" data-i18n="openPresetLists">Open preset lists</button>
                          <button type="button" class="btn blue" onclick="setPage('config')" data-i18n="openConfig">Open config</button>
                          <button type="button" class="btn blue" onclick="setPage('live');setTab('resolved')" data-i18n="openResolvedIps">Open resolved IPs</button>
                          <button type="button" class="btn blue" onclick="setPage('live');setTab('excludenets')" data-i18n="openExcludeRanges">Open exclude ranges</button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="page" id="page_presets">
                  <div class="panel">
                    <div class="panel-title" data-i18n="presetLists">Presetlijsten</div>
                    <div class="panel-body">
                      <div class="note" data-i18n-html="presetNote"></div>
                      <div class="search"><input id="presetSearch" data-i18n-placeholder="presetSearch" placeholder="Zoek op naam, domein of bereik…" oninput="filterPresets()"></div>
                      <div class="helperBar">
                        <button type="button" class="btn blue" onclick="selectAllVisible(true)" data-i18n="selectAllVisible">Select all visible</button>
                        <button type="button" class="btn" onclick="selectAllVisible(false)" data-i18n="clearVisible">Clear visible</button>
                        <button type="button" class="btn blue" onclick="setPage('config')" data-i18n="openConfig">Open config</button>
                      </div>
                      <div class="smallinfo" data-i18n-html="presetStatus"></div>
                      <div class="presetGrid" id="presetWrap"></div>
                      <div class="actions presetSaveBar" id="presetSaveBar" style="margin-top:12px">
                        <button type="button" class="btn blue" onclick="applyAction('save_config')" data-i18n="saveConfig">Save config</button>
                        <button type="button" class="btn orange" onclick="applyAction('save_config_restart')" data-i18n="saveRestart">Save + Restart</button>
                        <button type="button" class="btn" onclick="discardLocalChanges()" data-i18n="reloadConfig">Reload from config</button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="footer" data-i18n="footer">vpn_ipcatcher UI v11 - ASUS Merlin-integratie</div>
              </div>
            </div>
            </td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<div id="footer"></div>
</body>
</html>
