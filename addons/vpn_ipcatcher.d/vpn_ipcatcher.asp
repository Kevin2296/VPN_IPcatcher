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
/* VPN IP Catcher WebUI - Asuswrt-Merlin look (2.10)
   Colours follow the stock ASUS pages: content #4D595D, FormTable rows
   #475A5F with #1F2D35 label cells, grey-blue section bars and the dark
   button_gen gradient with the cyan hover. */
.vpn_ipcatcher_dashboard{
  --vp-bg:#4D595D; --vp-row:#475A5F; --vp-row-alt:#4F6267; --vp-label:#1F2D35; --vp-tile:#2F3A3E;
  --vp-line:#222E33; --vp-soft:#5E7177; --vp-text:#FFFFFF; --vp-muted:#C1CFD3; --vp-dim:#9DB0B6;
  --vp-accent:#2BC0F0; --vp-yellow:#FFCC00; --vp-green:#43D18E; --vp-red:#FF6B5E; --vp-violet:#C9A6FF;
  width:100%; background:var(--vp-bg); color:var(--vp-text); font-family:Arial,Helvetica,sans-serif; font-size:13px;
}
.vpn_ipcatcher_dashboard *{box-sizing:border-box}
.vpn_ipcatcher_dashboard [hidden]{display:none!important}
.vpn_ipcatcher_dashboard .wrap{padding:10px 14px 14px}
.vpn_ipcatcher_dashboard a{color:var(--vp-accent)}

/* Page title like other Merlin add-on pages */
.vpn_ipcatcher_dashboard .topbar{padding:4px 0 10px;border-bottom:1px solid #7E8593;margin-bottom:12px}
.vpn_ipcatcher_dashboard .title{font-size:20px;font-weight:bold;color:#FFF;text-shadow:1px 1px 0 #000}
.vpn_ipcatcher_dashboard .subtitle{color:var(--vp-muted);font-size:12px;margin-top:3px}
.vpn_ipcatcher_dashboard .sessionMeta{display:flex;gap:18px;flex-wrap:wrap;margin-top:8px;font-size:13px;color:var(--vp-muted)}
.vpn_ipcatcher_dashboard .sessionMeta strong{color:var(--vp-yellow)}
.vpn_ipcatcher_dashboard .languageRow{float:right;display:flex;align-items:center;gap:8px;font-size:12px}
.vpn_ipcatcher_dashboard .languageRow select{width:auto}

/* Status tiles */
.vpn_ipcatcher_dashboard .grid{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:8px;margin:0 0 6px}
.vpn_ipcatcher_dashboard .card{background:var(--vp-tile);border:1px solid var(--vp-line);border-top:3px solid var(--vp-soft);border-radius:4px;padding:9px 10px;min-height:86px}
.vpn_ipcatcher_dashboard .card.accent{border-top-color:var(--vp-accent)}
.vpn_ipcatcher_dashboard .card.good{border-top-color:var(--vp-green)}
.vpn_ipcatcher_dashboard .card.attention{border-top-color:var(--vp-yellow)}
.vpn_ipcatcher_dashboard .card.violet{border-top-color:var(--vp-violet)}
.vpn_ipcatcher_dashboard .card h3{margin:0 0 6px;color:var(--vp-dim);font-size:11px;font-weight:bold;text-transform:uppercase;letter-spacing:.4px;line-height:1.2}
.vpn_ipcatcher_dashboard .big{font-size:24px;font-weight:bold;color:#FFF;line-height:1.1}
.vpn_ipcatcher_dashboard .muted{color:var(--vp-muted);font-size:12px}
.vpn_ipcatcher_dashboard .card .muted{overflow-wrap:anywhere}
.vpn_ipcatcher_dashboard .badge{display:inline-block;padding:3px 10px;border-radius:3px;font-size:12px;font-weight:bold;letter-spacing:.3px}
.vpn_ipcatcher_dashboard .ok{background:#1E7A4C;color:#E5FFF1}
.vpn_ipcatcher_dashboard .bad{background:#8F2F28;color:#FFE6E3}
.vpn_ipcatcher_dashboard .warn{background:#8A6D12;color:#FFF5CF}

/* Hint / attention bars (ASUS yellow hint colour) */
.vpn_ipcatcher_dashboard .note{background:#3C4B50;border-left:3px solid var(--vp-yellow);padding:9px 12px;margin:0 0 10px;color:#F1F5F6;line-height:1.45}
.vpn_ipcatcher_dashboard .alertBar{display:flex;gap:12px;align-items:center;flex-wrap:wrap;background:#3C4B50;border-left:3px solid var(--vp-yellow);padding:8px 12px;margin:8px 0 10px}
.vpn_ipcatcher_dashboard .alertBar span{flex:1 1 300px;line-height:1.4}

/* Sections styled like ASUS FormTable */
.vpn_ipcatcher_dashboard .panel{background:var(--vp-row);border:1px solid var(--vp-line);margin:10px 0;border-radius:0}
.vpn_ipcatcher_dashboard .panel-title{background:linear-gradient(to bottom,#92A0A5 0%,#66757C 100%);color:#FFF;font-weight:bold;padding:7px 10px;font-size:13px;text-shadow:1px 1px 0 #2B3437}
.vpn_ipcatcher_dashboard .panel-body{padding:10px}
.vpn_ipcatcher_dashboard #page_routing>.panel-title,.vpn_ipcatcher_dashboard #page_help>.panel-title{margin-top:10px}
.vpn_ipcatcher_dashboard #page_routing>.panel-body,.vpn_ipcatcher_dashboard #page_help>.panel-body{background:var(--vp-row);border:1px solid var(--vp-line);border-top:0}
.vpn_ipcatcher_dashboard .split{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.vpn_ipcatcher_dashboard .split>.panel{margin:10px 0 0}

/* Buttons: ASUS button_gen */
.vpn_ipcatcher_dashboard .actions,.vpn_ipcatcher_dashboard .helperBar{display:flex;gap:6px;flex-wrap:wrap;align-items:center}
.vpn_ipcatcher_dashboard .btn{background:linear-gradient(to bottom,#233438 0%,#0F1517 100%);color:#FFF;border:0;border-radius:8px;min-height:30px;padding:6px 14px;font-size:12px;font-weight:bold;cursor:pointer;font-family:inherit}
.vpn_ipcatcher_dashboard .btn:hover,.vpn_ipcatcher_dashboard .btn:focus-visible{background:linear-gradient(to bottom,#27C9C9 0%,#279FD9 100%);outline:none}
.vpn_ipcatcher_dashboard .btn.blue{box-shadow:inset 0 0 0 1px var(--vp-accent)}
.vpn_ipcatcher_dashboard .btn.green{box-shadow:inset 0 0 0 1px var(--vp-green)}
.vpn_ipcatcher_dashboard .btn.red{box-shadow:inset 0 0 0 1px var(--vp-red)}
.vpn_ipcatcher_dashboard .btn.orange{box-shadow:inset 0 0 0 1px var(--vp-yellow)}
.vpn_ipcatcher_dashboard .btn.red:hover,.vpn_ipcatcher_dashboard .btn.danger:hover{background:linear-gradient(to bottom,#E0574B 0%,#A8352C 100%)}
.vpn_ipcatcher_dashboard .btn:disabled{opacity:.5;cursor:wait}
.vpn_ipcatcher_dashboard .btn.small{min-height:24px;padding:3px 10px;font-size:11px}

/* Page tabs like ASUS sub tabs */
.vpn_ipcatcher_dashboard .layoutTabs{display:flex;flex-wrap:wrap;gap:2px;margin:14px 0 0;border-bottom:2px solid var(--vp-accent)}
.vpn_ipcatcher_dashboard .layoutTab{background:var(--vp-tile);color:#DDE6E8;border:1px solid var(--vp-line);border-bottom:0;border-radius:6px 6px 0 0;padding:8px 14px;font-size:13px;font-weight:bold;cursor:pointer;font-family:inherit}
.vpn_ipcatcher_dashboard .layoutTab:hover{color:#FFF;background:#3A484C}
.vpn_ipcatcher_dashboard .layoutTab.active{background:var(--vp-accent);color:#0F1E24;border-color:var(--vp-accent)}
.vpn_ipcatcher_dashboard .tabs{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:10px}
.vpn_ipcatcher_dashboard .tab{background:var(--vp-label);color:#DDE6E8;border:1px solid #33464D;border-radius:4px;padding:6px 11px;font-size:12px;font-weight:bold;cursor:pointer;font-family:inherit}
.vpn_ipcatcher_dashboard .tab:hover{background:#2C3E45}
.vpn_ipcatcher_dashboard .tab.active{background:#2C5E6E;border-color:var(--vp-accent);color:#FFF}
.vpn_ipcatcher_dashboard .page{display:none}
.vpn_ipcatcher_dashboard .page.active{display:block}

/* Forms: label cells like FormTable th, inputs like ASUS input_32_table */
.vpn_ipcatcher_dashboard .formgrid{display:grid;grid-template-columns:260px 1fr;gap:0;border:1px solid var(--vp-line)}
.vpn_ipcatcher_dashboard .formgrid>label{background:var(--vp-label);color:#FFF;padding:9px 10px;border-bottom:1px solid var(--vp-line);display:flex;align-items:center;font-weight:bold;font-size:12px}
.vpn_ipcatcher_dashboard .formgrid>input,.vpn_ipcatcher_dashboard .formgrid>select,.vpn_ipcatcher_dashboard .formgrid>textarea,.vpn_ipcatcher_dashboard .formgrid>.fieldCell{margin:0;border-bottom:1px solid var(--vp-line)}
.vpn_ipcatcher_dashboard .formgrid>.fieldCell{background:var(--vp-row);padding:6px 8px}
.vpn_ipcatcher_dashboard input,.vpn_ipcatcher_dashboard select,.vpn_ipcatcher_dashboard textarea{background:#576D73;color:#FFF;border:1px solid #929EA1;border-radius:3px;padding:6px 8px;font-size:13px;font-family:Arial,Helvetica,sans-serif;width:100%}
.vpn_ipcatcher_dashboard input[type=checkbox]{width:auto;accent-color:var(--vp-accent)}
.vpn_ipcatcher_dashboard .formgrid>input,.vpn_ipcatcher_dashboard .formgrid>select,.vpn_ipcatcher_dashboard .formgrid>textarea{border-radius:0;border-left:0;border-right:0;border-top:0;border-color:var(--vp-line);background:#566B71}
.vpn_ipcatcher_dashboard textarea{min-height:92px;font-family:"Lucida Console",Monaco,monospace;font-size:12px;line-height:1.5}
.vpn_ipcatcher_dashboard input[readonly]{background:#3E4F54;color:#C9D6D9}
.vpn_ipcatcher_dashboard input:focus,.vpn_ipcatcher_dashboard select:focus,.vpn_ipcatcher_dashboard textarea:focus{outline:1px solid var(--vp-accent);outline-offset:-1px}
.vpn_ipcatcher_dashboard .settingsGroup{margin:12px 0 0;border:0;padding:0}
.vpn_ipcatcher_dashboard .settingsGroup legend,.vpn_ipcatcher_dashboard .settingsGroup>summary{background:linear-gradient(to bottom,#92A0A5 0%,#66757C 100%);color:#FFF;font-weight:bold;padding:7px 10px;width:100%;text-shadow:1px 1px 0 #2B3437;cursor:default}
.vpn_ipcatcher_dashboard details.settingsGroup>summary{cursor:pointer}
.vpn_ipcatcher_dashboard .saveBar{position:sticky;bottom:0;background:var(--vp-bg);padding:10px 0;border-top:1px solid #7E8593;z-index:2}
.vpn_ipcatcher_dashboard #pendingBar{background:#3C4B50;border-left:3px solid var(--vp-yellow);padding:8px 12px;margin:8px 0}

/* Device picker for source IPs */
.vpn_ipcatcher_dashboard .devicePicker{margin-top:6px;border:1px solid var(--vp-line);background:var(--vp-tile);max-height:260px;overflow:auto}
.vpn_ipcatcher_dashboard .deviceRow{display:flex;gap:10px;align-items:center;padding:6px 10px;border-bottom:1px solid #26343A;cursor:pointer}
.vpn_ipcatcher_dashboard .deviceRow:hover{background:#38484D}
.vpn_ipcatcher_dashboard .deviceRow .deviceName{flex:1;font-weight:bold}
.vpn_ipcatcher_dashboard .deviceRow .deviceIp{font-family:"Lucida Console",Monaco,monospace;color:var(--vp-muted)}

/* Data tables */
.vpn_ipcatcher_dashboard table.data{width:100%;border-collapse:collapse;font-size:12px;border:1px solid var(--vp-line)}
.vpn_ipcatcher_dashboard table.data th{background:var(--vp-label);color:#FFF;text-align:left;padding:7px 9px;font-weight:bold;border-bottom:1px solid var(--vp-line);white-space:nowrap}
.vpn_ipcatcher_dashboard table.data td{padding:6px 9px;border-bottom:1px solid #3D4F54;vertical-align:top}
.vpn_ipcatcher_dashboard table.data tbody tr:nth-child(even) td{background:var(--vp-row-alt)}
.vpn_ipcatcher_dashboard table.data tbody tr:hover td{background:#56696F}
.vpn_ipcatcher_dashboard .panel-body>table.data th{width:34%}
.vpn_ipcatcher_dashboard .scroll{max-height:470px;overflow:auto;border:1px solid var(--vp-line)}
.vpn_ipcatcher_dashboard .scroll table.data{border:0}
.vpn_ipcatcher_dashboard .scroll thead th{position:sticky;top:0;z-index:1}
.vpn_ipcatcher_dashboard .columnSort{display:flex;align-items:center;justify-content:space-between;gap:6px;width:100%;padding:0;margin:0;background:none;border:0;color:inherit;font:inherit;text-align:left;cursor:pointer}
.vpn_ipcatcher_dashboard .columnSort:focus-visible{outline:2px solid var(--vp-accent);outline-offset:3px}
.vpn_ipcatcher_dashboard .mono{font-family:"Lucida Console",Monaco,monospace}
.vpn_ipcatcher_dashboard pre{white-space:pre-wrap;word-break:break-word;background:var(--vp-tile);border:1px solid var(--vp-line);padding:10px;color:#E3ECEE;max-height:440px;overflow:auto;font-size:12px;line-height:1.4}

/* Flow status pills */
.vpn_ipcatcher_dashboard .flowState{display:inline-block;padding:2px 8px;border-radius:3px;font-size:11px;font-weight:bold;white-space:nowrap;background:#3B4A4F;color:#DDE6E8}
.vpn_ipcatcher_dashboard .flowState.final{background:#1E7A4C;color:#E5FFF1}
.vpn_ipcatcher_dashboard .flowState.waiting{background:#8A6D12;color:#FFF5CF}
.vpn_ipcatcher_dashboard .flowState.candidate{background:#1D5D73;color:#E2F7FF}
.vpn_ipcatcher_dashboard .flowState.fixed{background:#5B3F86;color:#F2E9FF}
.vpn_ipcatcher_dashboard .flowState.excluded{background:#59656A;color:#F0F3F4}
.vpn_ipcatcher_dashboard .flowState.router,.vpn_ipcatcher_dashboard .flowState.local{background:#334146;color:#AFC1C6}

/* Filters */
.vpn_ipcatcher_dashboard .liveFilters{display:flex;flex-wrap:wrap;gap:8px;align-items:flex-end;margin:8px 0}
.vpn_ipcatcher_dashboard .liveFilters label{display:flex;flex:1 1 140px;flex-direction:column;gap:4px;font-size:12px;color:var(--vp-muted);min-width:0}
.vpn_ipcatcher_dashboard #flowControls{display:flex;flex:3 1 420px;gap:8px;flex-wrap:wrap}
.vpn_ipcatcher_dashboard #flowControls[hidden]{display:none}

/* Presets */
.vpn_ipcatcher_dashboard .search{margin-bottom:10px}
.vpn_ipcatcher_dashboard .presetGrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;align-items:start}
.vpn_ipcatcher_dashboard .deviceTag{display:block;font-family:Arial,Helvetica,sans-serif;font-weight:bold;color:#FFF}
.vpn_ipcatcher_dashboard .presetCard{background:var(--vp-row);border:1px solid var(--vp-line)}
.vpn_ipcatcher_dashboard .presetCard h4{margin:0;background:linear-gradient(to bottom,#92A0A5 0%,#66757C 100%);color:#FFF;padding:7px 10px;font-size:13px;text-shadow:1px 1px 0 #2B3437}
.vpn_ipcatcher_dashboard .presetCard>.presetMeta:first-of-type{padding:7px 10px 0}
.vpn_ipcatcher_dashboard .presetItem{display:flex;gap:10px;align-items:flex-start;padding:8px 10px;border-top:1px solid #3D4F54}
.vpn_ipcatcher_dashboard .presetItem:first-of-type{border-top:0}
.vpn_ipcatcher_dashboard .presetItem input.presetCheck{margin-top:2px;width:16px;height:16px}
.vpn_ipcatcher_dashboard .presetMeta{font-size:12px;color:var(--vp-muted);margin-top:3px;line-height:1.4}
.vpn_ipcatcher_dashboard .pill{display:inline-block;padding:1px 7px;border-radius:3px;background:var(--vp-label);color:#DDE6E8;font-size:11px;margin-right:4px}
.vpn_ipcatcher_dashboard .statusOn{color:var(--vp-green);font-weight:bold}
.vpn_ipcatcher_dashboard .statusPart{color:var(--vp-yellow);font-weight:bold}
.vpn_ipcatcher_dashboard .statusOff{color:var(--vp-dim);font-weight:bold}
.vpn_ipcatcher_dashboard .smallinfo{font-size:12px;color:var(--vp-muted);margin:6px 0 10px}
.vpn_ipcatcher_dashboard .previewList{max-height:240px;overflow:auto;line-height:1.6;overflow-wrap:anywhere}

/* Collapsible blocks */
.vpn_ipcatcher_dashboard details>summary{cursor:pointer;color:var(--vp-muted);font-weight:bold;padding:4px 0}
.vpn_ipcatcher_dashboard details>summary:hover{color:#FFF}
.vpn_ipcatcher_dashboard .maintenance{margin:0;padding:0 10px 10px}
.vpn_ipcatcher_dashboard .maintenance .actions{margin-top:6px}
.vpn_ipcatcher_dashboard .maintenance .danger-zone{margin-top:10px;border-top:1px dashed #6B7C81;padding-top:6px}
.vpn_ipcatcher_dashboard .maintenance .danger-zone>summary{color:#FFB3AB}
.vpn_ipcatcher_dashboard #toast{color:var(--vp-yellow);font-weight:normal;margin-left:10px}

.vpn_ipcatcher_dashboard .footer{color:var(--vp-dim);font-size:11px;margin:14px 0 0;text-align:right}
.vpn_ipcatcher_dashboard h3{color:var(--vp-yellow);font-size:14px;margin:16px 0 6px}
.vpn_ipcatcher_dashboard p{line-height:1.5}

@media(max-width:1100px){.vpn_ipcatcher_dashboard .grid{grid-template-columns:repeat(3,minmax(0,1fr))}}
@media(max-width:800px){
  .vpn_ipcatcher_dashboard .grid{grid-template-columns:repeat(2,minmax(0,1fr))}
  .vpn_ipcatcher_dashboard .split,.vpn_ipcatcher_dashboard .presetGrid{grid-template-columns:1fr}
  .vpn_ipcatcher_dashboard .formgrid{grid-template-columns:1fr}
  .vpn_ipcatcher_dashboard .languageRow{float:none;margin-bottom:6px}
  .vpn_ipcatcher_dashboard .layoutTab{padding:7px 9px;font-size:12px}
}
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
var liveScrollPositions={},renderedLiveTab='',liveSortStates={};
var PRESET_CATEGORIES = [], protectedPresetIps = [], configLoaded = false, pendingPresetKeys = {};
var loadedConfigRevision = '', externalConfigWarningShown = false;
var loadedConfigValues = {};



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
    footer:'VPN IP Catcher - Asuswrt-Merlin',
    running:'ACTIEF', stopped:'GESTOPT', loading:'LADEN', noData:'Geen gegevens.',
    bytes:'Bytes', source:'Bron', destination:'Bestemming', port:'Poort', cand:'Kand.', hint:'Hint', timestamp:'Tijdstip', message:'Bericht', field:'Veld', value:'Waarde', timeout:'Time-out', packets:'Pakketten', seen:'Gezien', hostnameDomain:'Hostnaam / domein', range:'Bereik', comment:'Opmerking',
    serviceRunning:'Service draait en de workerprocessen zijn actief.', serviceStopped:'Service staat uit.', allDevices:'alle apparaten (LAN + Wi-Fi) - meer ruis',
    configPreparing:'Configuratie voorbereiden', configSending:'Configuratie verzenden', restartStarted:'Herstart gestart', saveFinishing:'Opslag afronden',
    configNotLoaded:'Configuratie is nog niet geladen; wacht op de statusverversing.', sendingConfig:'Configuratie wordt veilig naar de router gestuurd…', actionSent:'Actie verzonden: {action}…',
    waitingConfirmation:'Wachten op bevestiging van de router…', saveSuccess:'Configuratie is door de router opgeslagen.', saveRestartSuccess:'Configuratie is opgeslagen en de engine is herstart.', actionSuccess:'Actie succesvol uitgevoerd.',
    routerActionFailed:'De router meldde dat de actie is mislukt.', noConfirmation:'Geen bevestiging ontvangen. Controleer /jffs/scripts/service-event.', externalChanged:'De configuratie is intussen via amtm gewijzigd. Sla lokaal op of kies Opnieuw laden uit configuratie.',
    localDiscarded:'Lokale wijzigingen zijn verworpen; de configuratie wordt opnieuw geladen.', addedConfig:'Toegevoegd aan configuratie: ', removedConfig:'Verwijderd uit configuratie: ', rememberSave:' - vergeet Configuratie opslaan of Opslaan + herstarten niet',
    presetsLoading:'Presetdatabase wordt geladen…', presetLoadFailed:'Presetdatabase kon niet worden geladen: ', streamAckTimeout:'Ontvangst configuratiedeel niet bevestigd:',streamAckError:'Configuratiedeel door router afgewezen:',savedConfigMismatch:'De opgeslagen uitsluitingen wijken af van je selectie. Lokale wijzigingen blijven staan.',noChangesToSave:'Geen gewijzigde instellingen om op te slaan.',jsonFailed:'JSON kon niet worden gelezen. Fout: ',
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
    footer:'VPN IP Catcher - Asuswrt-Merlin',
    running:'RUNNING', stopped:'STOPPED', loading:'LOADING', noData:'No data.',
    bytes:'Bytes', source:'Source', destination:'Destination', port:'Port', cand:'Cand', hint:'Hint', timestamp:'Timestamp', message:'Message', field:'Field', value:'Value', timeout:'Timeout', packets:'Packets', seen:'Seen', hostnameDomain:'Hostname / domain', range:'Range', comment:'Comment',
    serviceRunning:'Service is running and the worker processes are active.', serviceStopped:'Service is stopped.', allDevices:'all devices (LAN + Wi-Fi) - more noise',
    configPreparing:'Preparing configuration', configSending:'Sending configuration', restartStarted:'Restart started', saveFinishing:'Finishing save',
    configNotLoaded:'Configuration has not loaded yet; wait for the status refresh.', sendingConfig:'Sending configuration safely to the router…', actionSent:'Action sent: {action}…',
    waitingConfirmation:'Waiting for confirmation from the router…', saveSuccess:'Configuration was saved by the router.', saveRestartSuccess:'Configuration was saved and the engine restarted.', actionSuccess:'Action completed successfully.',
    routerActionFailed:'The router reported that the action failed.', noConfirmation:'No confirmation received. Check /jffs/scripts/service-event.', externalChanged:'The configuration was changed through amtm. Save the local version or choose Reload from configuration.',
    localDiscarded:'Local changes were discarded; reloading the configuration.', addedConfig:'Added to configuration: ', removedConfig:'Removed from configuration: ', rememberSave:' - remember to use Save configuration or Save + restart',
    presetsLoading:'Loading preset database…', presetLoadFailed:'Preset database could not be loaded: ', streamAckTimeout:'Router did not acknowledge configuration chunk:',streamAckError:'Router rejected configuration chunk:',savedConfigMismatch:'Saved exclusions differ from your selection. Local changes are retained.',noChangesToSave:'No changed settings to save.',jsonFailed:'JSON could not be read. Error: ',
    auto:'auto', age:'age', immediate:'immediate', yes:'yes', no:'no', candidateValue:'candidate', finalValue:'final', emptyAllDevices:'empty = all devices', empty:'empty',
    cat_dns:'DNS providers', cat_social:'Social / messaging', cat_cameras:'Security cameras / IoT cloud', cat_github:'GitHub / dev CDN', cat_games:'Games / downloads', cat_updates:'OS / app updates', cat_tv:'Smart TV telemetry', cat_streaming:'Streaming services',
    note_dns:'Usually exclude these so DNS resolvers are never learned through VPN Director.', note_social:'Prevents Meta, WhatsApp, Instagram and Snapchat from being learned as collateral traffic.', note_cameras:'Excludes camera and IoT cloud traffic.', note_github:'Prevents GitHub/CDN traffic from being learned as a stream.', note_games:'Prevents large game downloads from being learned as streams.', note_updates:'Excludes updates and software CDN traffic.', note_tv:'Reduces background and telemetry traffic from smart TV platforms.', note_streaming:'Enable only for services that should NOT use this VPN rule.',
    domainsCount:'domains', rangesCount:'ranges', detailsDomains:'Domains', detailsRanges:'Ranges'
  }
};
var VPNIPC_CATEGORY_KEYS={
  'DNS providers':'cat_dns','Social / messaging':'cat_social','AI assistants':'cat_ai','Security cameras / IoT cloud':'cat_cameras','GitHub / dev CDN':'cat_github',
  'Games / downloads':'cat_games','OS / app updates':'cat_updates','Smart TV telemetry':'cat_tv','Streamingdiensten':'cat_streaming'
};
var VPNIPC_CATEGORY_NOTE_KEYS={
  'DNS providers':'note_dns','Social / messaging':'note_social','AI assistants':'note_ai','Security cameras / IoT cloud':'note_cameras','GitHub / dev CDN':'note_github',
  'Games / downloads':'note_games','OS / app updates':'note_updates','Smart TV telemetry':'note_tv','Streamingdiensten':'note_streaming'
};
var VPNIPC_PRESET_LABEL_NL={
  upd_apple:'Apple / iCloud-updates',upd_google:'Google / Android-updates',upd_google_play:'Google Play Store / app-downloads',tv_samsung:'Samsung Smart TV-telemetrie',tv_philips:'Philips Smart TV-telemetrie',tv_android:'Android TV-telemetrie',tv_lg:'LG Smart TV-telemetrie'
};
function vpnipcRouterLanguage(){
  var raw=String((byId('routerPreferredLang')||{}).value||'').toLowerCase();
  return raw.indexOf('nl')===0?'nl':'en';
}
function vpnipcResolveLanguage(mode){return mode==='nl'||mode==='en'?mode:vpnipcRouterLanguage();}
Object.assign(VPNIPC_I18N.nl,{cat_ai:'AI-assistenten',note_ai:'Voorkomt dat AI-chat en bestandsdownloads als IPTV worden geleerd.'});
Object.assign(VPNIPC_I18N.en,{cat_ai:'AI assistants',note_ai:'Prevent AI chat and file downloads from being learned as IPTV.'});
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

Object.assign(VPNIPC_I18N.nl,{autoUpdateConfirm:'amtm toestaan om nieuwere versies te installeren met verplichte lokale back-up? Dit registreert de addon niet automatisch in de centrale AU-lijst en maakt geen eigen tijdschema.',autoUpdateEnable:'amtm-updates toestaan',autoUpdateDisable:'amtm-updates uitschakelen',autoUpdateOn:'amtmupdate toegestaan; centrale AU-registratie vereist',autoUpdateOff:'amtmupdate uitgeschakeld'});
Object.assign(VPNIPC_I18N.en,{autoUpdateConfirm:'Allow amtm to install newer versions with a mandatory local backup? This does not register the addon in the central AU catalog and does not create a separate schedule.',autoUpdateEnable:'Allow amtm updates',autoUpdateDisable:'Disable amtm updates',autoUpdateOn:'amtmupdate allowed; central AU registration required',autoUpdateOff:'amtmupdate disabled'});
Object.assign(VPNIPC_I18N.nl,{forceVpnHelp:'Plak desgewenst een EPG/XMLTV-link: alleen de hostname wordt aan de gekozen VPN-policy gekoppeld. De handmatige regel heeft voorrang op automatisch IPTV-leren. Op gedeelde CDN-IP’s en bij privé-DNS is per URL-pad routeren niet mogelijk.'});
Object.assign(VPNIPC_I18N.en,{forceVpnHelp:'Paste an EPG/XMLTV URL: only its hostname is assigned to the selected VPN policy. The manual rule takes priority over automatic IPTV learning. Shared CDN addresses and private DNS cannot be routed per URL path.'});
Object.assign(VPNIPC_I18N.nl,{
  help:'Uitleg',routing:'Domeinroutes',dvrChoose:'Kies DVR-policy',dvrDomain:'EPG-URL of hostnaam',dvrAdd:'Altijd via VPN instellen',dvrInvalid:'Kies een DVR-policy en vul een hostnaam of HTTP(S)-EPG-URL zonder gebruikersnaam/wachtwoord in.',dvrConfirm:'Deze host altijd direct via de geselecteerde VPN-policy routeren, zonder IPTV-learning? Alleen de hostnaam wordt opgeslagen. Er wordt eerst een lokale back-up gemaakt.',
  checkUpdate:'Update controleren',installUpdate:'Update installeren',forceUpdate:'Opnieuw installeren',updateConfirm:'Update installeren? Voor wijzigingen wordt automatisch een verplichte lokale back-up gemaakt. Je instellingen blijven behouden.',forceUpdateConfirm:'De gepubliceerde versie opnieuw installeren, ook als het versienummer gelijk is? Voor wijzigingen wordt een verplichte lokale back-up gemaakt.',saveBeforeUpdate:'Sla eerst je gewijzigde instellingen op of verwerp ze.',
  helpLists:'Kandidaat: tijdelijk ontdekt IP, nog niet voldoende beoordeeld. Wachtlijst: IP klaar voor routering, maar een bestaande verbinding moet eerst eindigen om geen actieve stream van uitgangs-IP te laten wisselen. Definitief: IP in de VPN-lijst, met een vervaltijd; niet permanent.',
  helpRouting:'IP Catcher hergebruikt een passende bestaande DVR-IPSet of maakt eigen tijdelijke IPSet-lijsten en markregels. Die eigen lijsten zijn geen nieuwe permanente DVR-domeinpolicy. Domeinroutes voeg je apart toe aan een bestaande DVR-policy. Alleen IPv4 wordt geleerd.',
  helpPresets:'Presets sluiten verkeer uit van het leren; aanvinken betekent NIET via deze catcher laten leren. Andere ASUS/DVR-regels blijven gelden. Onder Details kun je losse domeinen, IPs en netwerken selecteren. Een gedeeld item kan ook bij andere presets voorkomen. Sla wijzigingen daarna op.',
  helpDns:'Domeinnamen komen uit DNS-verkeer van het gekozen apparaat tijdens de meting. Een IP heeft niet automatisch een unieke domeinnaam. Gecachte DNS, directe IP-URLs en versleutelde DNS kunnen ontbreken. DNS-aanwijzingen bewijzen niet welke app het verkeer gebruikt. Herstart de app of het apparaat tijdens een nieuwe meting. Diagnose blijft lokaal; exporteren downloadt alleen naar je eigen computer.',
  helpUpdates:'Updates via de browser vragen bevestiging en maken voor wijzigingen een lokale back-up. Opnieuw installeren repareert dezelfde versie. Back-ups beheren en terugzetten kan in het terminalmenu. amtmupdate-ondersteuning is niet hetzelfde als opname in de centrale amtm AU-lijst.',
  dnsState_idle:'DNS: geen meting',dnsState_starting:'DNS: capture wordt gestart',dnsState_capturing:'DNS: capture actief (TCP/UDP 53)',dnsState_finished:'DNS: capture afgerond',dnsState_tools_missing:'DNS: tcpdump of timeout ontbreekt',dnsState_capture_error:'DNS: capture mislukt; controleer tcpdump/timeout',dnsState_capture_busy:'DNS: vorige capture nog bezig',dnsState_unavailable:'DNS: capturestatus niet beschikbaar'
});
Object.assign(VPNIPC_I18N.en,{
  help:'Help',routing:'Domain routes',dvrChoose:'Choose DVR policy',dvrDomain:'EPG URL or hostname',dvrAdd:'Always route via VPN',dvrInvalid:'Choose a DVR policy and supply a hostname or HTTP(S) EPG URL without embedded credentials.',dvrConfirm:'Always send this host through the selected VPN policy without IPTV learning? Only the hostname is saved. A local backup is created first.',
  checkUpdate:'Check update',installUpdate:'Install update',forceUpdate:'Reinstall',updateConfirm:'Install update? A mandatory local backup is made before changes. Your settings are preserved.',forceUpdateConfirm:'Reinstall the published version even if its version number is unchanged? A mandatory local backup is made before changes.',saveBeforeUpdate:'Save or discard your modified settings first.',
  helpLists:'Candidate: temporarily discovered IP, still being assessed. Waiting: ready for routing but an existing connection must end first, to avoid changing the exit IP of an active stream. Final: IP in the VPN list with an expiry time; not permanent.',
  helpRouting:'IP Catcher reuses a suitable existing DVR IPSet or creates its own temporary IPSets and marking rules. These managed sets are not new permanent DVR domain policies. Add domain routes separately to an existing DVR policy. Learning supports IPv4 only.',
  helpPresets:'Presets exclude traffic from learning; checking one does NOT request VPN routing. Other ASUS/DVR rules still apply. Expand Details to select individual domains, IPs and networks. Shared entries can affect other presets. Save your changes afterwards.',
  helpDns:'Domain names come from DNS traffic of the selected device during measurement. An IP does not automatically have a unique domain. Cached DNS, direct IP URLs and encrypted DNS may be absent. DNS hints do not prove which app uses a connection. Restart the app or device during a new measurement. Diagnostics stay local; exporting only downloads to your own computer.',
  helpUpdates:'Browser updates ask for confirmation and make a local backup before changes. Reinstall repairs the same version. Manage backups and restore through the terminal menu. amtmupdate support does not mean inclusion in the central amtm AU catalog.',
  dnsState_idle:'DNS: no measurement',dnsState_starting:'DNS: starting capture',dnsState_capturing:'DNS: capture active (TCP/UDP 53)',dnsState_finished:'DNS: capture finished',dnsState_tools_missing:'DNS: tcpdump or timeout missing',dnsState_capture_error:'DNS: capture failed; check tcpdump/timeout',dnsState_capture_busy:'DNS: previous capture still busy',dnsState_unavailable:'DNS: capture status unavailable'
});
function applyStatusData(d){
  dataCache=d;
  if(Array.isArray(d.protected_ips)) protectedPresetIps=d.protected_ips;
  updateOverview(d);
  fillConfig(d.config,d.config_revision);
  renderLiveTab();
  renderPresets();
  var picker=byId('devicePicker'); if(picker&&!picker.hidden) renderDevicePicker();
}
function waitForActionResult(nonce, attempts){
  return fetch('/user/vpn_ipcatcher_status.json?ts='+Date.now(),{cache:'no-store'})
    .then(function(r){if(!r.ok) throw new Error('status HTTP '+r.status); return r.json();})
    .then(function(d){
      applyStatusData(d);
      if(String(d.last_action_nonce||'')===String(nonce)){
        if(d.last_action_status==='ok') return d;
        if(d.last_action_status!=='running') throw new Error(d.last_action_message||t('routerActionFailed'));
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
function normalizeConfigValue(value){
  return String(value==null?'':value).replace(/\r?\n/g,' ').replace(/\s+/g,' ').trim();
}
function buildConfigPayload(){
  // Send only changed values: preset changes must not overwrite unrelated settings.
  var keys=['INTERFACES','IPSET_NAME','PORTS','PROMOTE_MODE','PROMOTE_EVERY','MIN_AGE','MIN_BYTES','CANDIDATE_TIMEOUT','FINAL_TIMEOUT','STREAM_FLOW_SCAN','SOURCE_IPS','STREAM_SCAN_EVERY','STREAM_MIN_BYTES','STREAM_MIN_DELTA','STREAM_REQUIRE_GROWTH','STREAM_FLOW_TARGET','EXCLUDE_DOMAINS','EXCLUDE_IPS','EXCLUDE_NETS','EXCLUDE_RESOLVE_CACHE','EXCLUDE_RESOLVE_EVERY','PROVIDER_RANGE_AUTO','REVERSE_DNS_CHECK','CAPTURE_GENERIC_HOSTNAMES','ALLOW_EXTERNAL_DNS','EXTERNAL_DNS_SERVER','RETRY_DELAY','MAX_RETRY_DELAY'];
  var lines=[];
  keys.forEach(function(k){
    var el=byId('cfg_'+k);
    if(!el) return;
    var value=normalizeConfigValue(el.value);
    if(!Object.prototype.hasOwnProperty.call(loadedConfigValues,k) ||
       value!==normalizeConfigValue(loadedConfigValues[k])) lines.push(k+'='+value);
  });
  return lines.length?lines.join('\n')+'\n':'';
}
function waitForStreamReceipt(nonce,next,tries){
  return fetch('/user/vpn_ipcatcher_stream_ack.json?ts='+Date.now(),{cache:'no-store',credentials:'same-origin'})
    .then(function(r){return r.ok?r.json():null;})
    .catch(function(){return null;})
    .then(function(ack){
      if(ack && String(ack.nonce)===String(nonce)){
        if(ack.state==='error')throw new Error(t('streamAckError')+' '+next);
        if(Number(ack.next)===next && (ack.state==='ready'||ack.state==='received'))return true;
      }
      if(tries<=0)throw new Error(t('streamAckTimeout')+' '+next);
      return new Promise(function(resolve){setTimeout(resolve,250);})
        .then(function(){return waitForStreamReceipt(nonce,next,tries-1);});
    });
}
function configExclusionsMatch(saved,expected){
  if(!saved||!expected)return false;
  return ['EXCLUDE_DOMAINS','EXCLUDE_IPS','EXCLUDE_NETS'].every(function(k){
    return !Object.prototype.hasOwnProperty.call(expected,k) ||
      getWords(saved[k]).join(' ')===getWords(expected[k]).join(' ');
  });
}
function exclusionValuesFromPayload(payload){
  var values={};
  String(payload||'').split('\n').forEach(function(line){
    var pos=line.indexOf('='),key=line.slice(0,pos);
    if(pos>0 && ['EXCLUDE_DOMAINS','EXCLUDE_IPS','EXCLUDE_NETS'].indexOf(key)>=0)values[key]=line.slice(pos+1).trim();
  });
  return values;
}
function sendStreamedConfig(action,nonce,payload){
  var encoded=base64UrlEncode(payload===undefined?buildConfigPayload():payload);
  /* Houd de rc-service naam ruim onder de firmwarelimiet, maar voorkom tientallen extra requests. */
  var chunkSize=88;
  var chunks=[];
  for(var i=0;i<encoded.length;i+=chunkSize) chunks.push(encoded.slice(i,i+chunkSize));
  var total=chunks.length+2, sent=0;
  function progress(label){
    sent++;
    setText('toast',label+' ('+sent+'/'+total+')');
  }
  var chain=postRcEvent('vipcR'+nonce)
    .then(function(){return waitForStreamReceipt(nonce,0,64);})
    .then(function(){progress(t('configPreparing'));});
  chunks.forEach(function(chunk,n){
    chain=chain.then(function(){
      return postRcEvent('vipcA'+nonce+'_'+n+'_'+chunk)
        .then(function(){return waitForStreamReceipt(nonce,n+1,64);})
        .then(function(){progress(t('configSending'));});
    });
  });
  var finalAction=action==='dvr'?'dvr':((action==='save_config_restart')?'saverestart':'save');
  return chain.then(function(){
    return postRcEvent('vipcZ'+nonce+'_'+finalAction).then(function(){progress(action==='save_config_restart'?t('restartStarted'):t('saveFinishing'));});
  });
}
function sendSimpleAction(action,nonce){
  return postRcEvent('vipcX'+nonce+'_'+action);
}
function applyAction(action){
  if(actionBusy) return;
  if((action==='install_update'||action==='force_update')&&!window.confirm(t(action==='force_update'?'forceUpdateConfirm':'updateConfirm')))return;
  if(action==='auto_update_enable'&&!window.confirm(t('autoUpdateConfirm')))return;
  if((action==='install_update'||action==='force_update')&&dirty){showToast(t('saveBeforeUpdate'));return;}
  var isSave=(action==='save_config' || action==='save_config_restart');
  if(isSave && !configLoaded){showToast(t('configNotLoaded')); return;}
  var buttons=document.querySelectorAll('.vpn_ipcatcher_dashboard button[onclick*="applyAction"]');
  buttons.forEach(function(b){b.disabled=true;});
  actionBusy=true;
  var nonce=Date.now().toString(36);
  showToast(isSave?t('sendingConfig'):t('actionSent',{action:action}));
  var savePayload=isSave?buildConfigPayload():null;
  if(isSave && !savePayload){
    showToast(t('noChangesToSave'));
    buttons.forEach(function(b){b.disabled=false;});
    actionBusy=false; dirty=false; pendingPresetKeys={}; renderPresets();
    return;
  }
  var expectedExclusions=isSave?exclusionValuesFromPayload(savePayload):null;
  var sendPromise=isSave?sendStreamedConfig(action,nonce,savePayload):sendSimpleAction(action,nonce);
  sendPromise
    .then(function(){setText('toast',t('waitingConfirmation')); return waitForActionResult(nonce,action.indexOf('update')>=0?800:120);})
    .then(function(result){
      if(isSave && !configExclusionsMatch(result.config,expectedExclusions)){
        throw new Error(t('savedConfigMismatch'));
      }
      if(isSave){
        dirty=false; pendingPresetKeys={}; externalConfigWarningShown=false;
        loadedConfigRevision=result.config_revision||loadedConfigRevision;
        fillConfig(result.config,result.config_revision);
      }
      if(action.indexOf('update')>=0)setText('maintenanceResult',result.last_action_message||t('actionSuccess'));
      showToast(isSave?(action==='save_config_restart'?t('saveRestartSuccess'):t('saveSuccess')):t('actionSuccess'));
    })
    .catch(function(err){var message=err&&err.message?err.message:String(err);if(action.indexOf('update')>=0)setText('maintenanceResult',message);showToast('FOUT: '+message);})
    .then(function(){
      buttons.forEach(function(b){b.disabled=false;});
      actionBusy=false;
      var progress=byId('maintenanceProgress');if(progress)progress.hidden=true;
    });
  var progress=byId('maintenanceProgress');if(progress)progress.hidden=action.indexOf('update')<0;
}
// EPG URLs may contain private tokens in their path/query. Only send their
// validated hostname to the router; the DVR policy works at IP level.
function forceVpnHostname(input){
  var value=String(input||'').trim();
  if(!value||value.length>2048)return '';
  if(/^https?:\/\//i.test(value)){
    try{
      var url=new URL(value);
      if(url.username||url.password||!/^https?:$/.test(url.protocol))return '';
      value=url.hostname.toLowerCase();
    }catch(e){return '';}
  }else if(/[:\/?#@]/.test(value))return '';
  value=value.toLowerCase();
  if(/^[0-9.]+$/.test(value))return '';
  if(value.length>253||value.split('.').length<2||!value.split('.').every(function(part){
    return part.length<=63&&/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(part);
  }))return '';
  return value;
}
function addDvrDomain(){
  if(actionBusy)return;
  var domain=forceVpnHostname(byId('dvrDomain').value),policy=byId('dvrPolicy').value;
  if(!domain||!/^[A-Za-z0-9_-]{1,24}$/.test(policy)){showToast(t('dvrInvalid'));return;}
  if(!window.confirm(t('dvrConfirm')+'\n'+domain+' → '+policy))return;
  actionBusy=true;
  var nonce='v'+Date.now().toString(36);
  setText('dvrResult',t('waitingConfirmation'));
  sendStreamedConfig('dvr',nonce,'DOMAIN='+domain+'\nPOLICY='+policy+'\n')
    .then(function(){return waitForActionResult(nonce,800);})
    .then(function(result){setText('dvrResult',result.last_action_message||t('actionSuccess'));})
    .catch(function(error){setText('dvrResult',error.message||String(error));})
    .finally(function(){actionBusy=false;});
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
  loadedConfigValues={};
  Object.keys(cfg).forEach(function(k){loadedConfigValues[k]=normalizeConfigValue(cfg[k]);});
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
  headers.forEach(function(h,i){var sort=liveSortStates[currentTab],active=sort&&sort.column===i;html+='<th aria-sort="'+(active?(sort.descending?'descending':'ascending'):'none')+'"><button type="button" class="columnSort" onclick="sortLiveColumn('+i+')">'+escapeHtml(h)+' <span aria-hidden="true">'+(active?(sort.descending?'&#9660;':'&#9650;'):'&#8597;')+'</span></button></th>'});
  html+='</tr></thead><tbody>';
  rows.forEach(function(r){html+='<tr>'+r+'</tr>'});
  html+='</tbody></table></div>';
  return html;
}
function sortLiveColumn(column){
  var previous=liveSortStates[currentTab];
  liveSortStates[currentTab]={column:column,descending:!!(previous&&previous.column===column&&!previous.descending)};
  renderLiveTab();
}
function compareLiveValues(a,b){
  function numeric(value){
    var match=String(value).trim().match(/^([0-9]+(?:[.,][0-9]+)?)\s*(B|KB|MB|GB|TB)?$/i);
    return match?Number(match[1].replace(',','.'))*Math.pow(1000,['B','KB','MB','GB','TB'].indexOf((match[2]||'B').toUpperCase())):null;
  }
  var x=numeric(a),y=numeric(b);
  return x!==null&&y!==null?x-y:String(a).localeCompare(String(b),undefined,{numeric:true,sensitivity:'base'});
}
function applyLiveSort(box){
  var sort=liveSortStates[currentTab],body=box.querySelector?box.querySelector('tbody'):null;
  if(!sort||!body||!body.rows)return;
  var group=[];
  function flush(before){
    group.sort(function(a,b){var x=a.cells[sort.column],y=b.cells[sort.column];return (sort.descending?-1:1)*compareLiveValues(x.getAttribute('data-sort')||x.getAttribute('title')||x.textContent,y.getAttribute('data-sort')||y.getAttribute('title')||y.textContent);});
    group.forEach(function(row){body.insertBefore(row,before);});group=[];
  }
  Array.from(body.rows).forEach(function(row){if(row.cells.length>sort.column&&row.cells[0].colSpan===1)group.push(row);else flush(row);});
  flush(null);
}
function td(v, cls, sort){return '<td'+(cls?' class="'+cls+'"':'')+(sort!==undefined?' data-sort="'+escapeHtml(sort)+'"':'')+'>'+escapeHtml(v==null?'':v)+'</td>'}
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
Object.assign(VPNIPC_I18N.nl,{
  choosePresetItems:'Losse onderdelen kiezen',defaultsTitle:'Standaardwaarden bij nieuwe installatie',
  defaultsExplain:'Dit zijn de ingebouwde leerinstellingen, niet je huidige configuratie. Installatie kiest LAN en VPN/lijst automatisch. Updates bewaren je eigen waarden; een profiel kan andere waarden instellen.',
  promotionExplain:'auto: bytes wanneer conntrack-tellers werken, anders leeftijd. bytes: voldoende verkeer en minimale leeftijd vereist. age: alleen minimale leeftijd. immediate: direct geschikt voor de VPN-lijst, maar actieve verbindingen blijven beschermd.',
  defaultsAdvice:'Er is geen beste instelling voor iedereen. Beperk Bron-IP\'s bij voorkeur tot je mediaboxen om downloads van andere apparaten niet te leren. Laat generieke scan, externe DNS en omgekeerde DNS uit, tenzij je die bewust nodig hebt. Stabiel TV leert sneller dan deze basis; Voorzichtig is terughoudender. Een uitsluitpreset stuurt niets verplicht via VPN.'
});
Object.assign(VPNIPC_I18N.en,{
  choosePresetItems:'Choose individual entries',defaultsTitle:'Defaults for a new installation',
  defaultsExplain:'These are the built-in learning settings, not your current configuration. Installation selects LAN and VPN/list automatically. Updates preserve your values; profiles may use different settings.',
  promotionExplain:'auto: bytes when conntrack accounting works, otherwise age. bytes: sufficient traffic and minimum age required. age: minimum age only. immediate: immediately eligible for the VPN list, but existing connections remain protected.',
  defaultsAdvice:'There is no best configuration for everyone. Prefer limiting Source IPs to media devices to avoid learning downloads from other devices. Keep generic scanning, external DNS and reverse DNS disabled unless deliberately needed. Stable TV learns faster than this baseline; Cautious is more conservative. An exclusion preset does not force traffic through a VPN.'
});
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
    if(state==='waiting') return r.hint==='waiting';
    if(state==='fixed') return /^fixed/.test(r.hint||'');
    if(state==='router') return r.hint==='router'||r.hint==='local';
    if(state==='other') return r.final==='no' && r.cand==='no' && (r.hint==='watch'||!r.hint);
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
    var rows=diagnosticHistory.slice().reverse().map(function(entry){var p=entry.line.split(/\s+/);return p.length===6&&!/^MARKER /.test(entry.line)?td(new Date(entry.time).toLocaleString(),null,entry.time)+td(p[0])+td(p[1],'mono')+td(p[2],'mono')+td(entry.domain||t('diagnosticUnknown'))+td(p[3])+td(p[4])+td(formatFlowBytes(p[5]),null,p[5]):td(new Date(entry.time).toLocaleString(),null,entry.time)+'<td colspan="7">'+escapeHtml(entry.line)+'</td>';});
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
    var rows=filterLiveRows(flows).map(function(r){return r.raw?'<td colspan="7" class="mono">'+escapeHtml(r.raw)+'</td>':'<td class="mono" title="'+escapeHtml(r.bytes)+' B">'+escapeHtml(formatFlowBytes(r.bytes))+'</td>'+sourceCell(r.src)+destinationCell(r.dst)+td(r.port,'mono')+td(r.cand)+td(r.final)+flowStateCell(r);});
    html=renderTable([t('trafficVolume'),t('source'),t('destination'),t('port'),t('cand'),t('final'),t('flowStatus')], rows);
  } else if(currentTab==='log'){
    var rows=filterLiveRows(parseLog(txt)).map(function(r){return td(r.ts,'mono')+td(r.msg);});
    html=renderTable([t('timestamp'),t('message')], rows);
  } else if(currentTab==='status'){
    var rows=filterLiveRows(parseKeyValueStatus(txt)).map(function(r){return r.section?'<td colspan="2"><strong>'+escapeHtml(r.label)+'</strong></td>':td(r.key)+td(r.value);});
    html=renderTable([t('field'),t('value')], rows);
  } else if(currentTab==='candidate' || currentTab==='waiting' || currentTab==='final'){
    var dump=parseIpsetDump(txt), meta=dump.meta.length?'<pre>'+escapeHtml(dump.meta.join('\n'))+'</pre>':'';
    var rows=filterLiveRows(dump.rows.map(function(r){if(!r.raw){r.name=destinationName(r.ip);r.origin=describeOrigin(r.source);}return r;})).map(function(r){return r.raw?'<td colspan="6" class="mono">'+escapeHtml(r.raw)+'</td>':td(r.ip,'mono')+nameCell(r.ip)+td(r.timeout,'mono',Number(r.timeout))+td(formatFlowBytes(r.bytes),'mono',Number(r.bytes))+td(r.seen,'mono')+'<td title="'+escapeHtml(r.source)+'">'+escapeHtml(r.origin)+'</td>';});
    html='<div class="ipsetDump">'+meta+renderTable(['IP',t('destName'),t('timeout'),t('bytes'),t('seen'),t('learnedHow')], rows)+'</div>';
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
  applyLiveSort(box);
  var newScroll=box.querySelector?box.querySelector('.scroll'):null;
  var keep=byId('liveKeepPosition'),position=liveScrollPositions[currentTab];
  var frozenDiagnostic=currentTab==='diagnostic'&&diagnosticState!=='active';
  if(newScroll){
    if(frozenDiagnostic||!keep||keep.checked){
      newScroll.scrollTop=position?position.top:0;newScroll.scrollLeft=position?position.left:0;box.scrollLeft=position?position.outerLeft:0;
    }else{
      newScroll.scrollTop=currentTab==='log'?newScroll.scrollHeight:0;
    }
  }
  renderedLiveTab=currentTab;
}
/* 2.10 WebUI texts */
Object.assign(VPNIPC_I18N.nl,{
  subtitle:'IPTV-streams automatisch via de VPN, al het andere verkeer via WAN',
  fixedRoutes:'Vaste routes', fixedRoutesHint:'VPN Director / VPN Routing, nooit geleerd', waitingShort:'wachtlijst',
  fixedMetaText:'{dst} bestemmingen · {dev} apparaten · {pol} policies', fixedDestinations:'VPN Director-bestemmingen', fixedDevices:'VPN Director-apparaten', fixedPolicies:'VPN Routing-policies', none:'geen',
  waitingExplain:'{count} IP’s klaar voor de VPN; ze wisselen pas als de lopende stream stopt',
  sourceAlert:'IP Catcher kijkt nu naar alle apparaten. Kies je IPTV-box of tv als bronapparaat, dan kan ander verkeer nooit per ongeluk via de VPN gaan.',
  chooseDevices:'IPTV-apparaten kiezen', devicePickerClear:'Alle apparaten', devicePickerEmpty:'Geen online apparaten gevonden.', devicePickerOffline:'niet online',
  devicePickerSelected:'{count} apparaat/apparaten gekozen - sla daarna op', devicePickerChanged:'Bron-apparaten aangepast - vergeet Opslaan + herstarten niet',
  amtmAutoUpdate:'Automatische updates via amtm:', advancedDanger:'Geavanceerd (overschrijft instellingen)',
  flowStatus:'Status', filterWaiting:'Wachtlijst', filterFixed:'Vaste route', filterRouter:'Router / lokaal',
  flow_final:'via VPN', flow_waiting:'wacht op einde stream', flow_candidate:'in beoordeling', flow_watch:'via WAN',
  flow_fixed_route:'vaste route', flow_fixed_device:'vast apparaat', flow_excluded_range:'uitgesloten', flow_router:'router zelf', flow_local:'lokaal',
  flow_final_help:'Bestemming staat in de VPN-lijst.', flow_waiting_help:'Klaar voor de VPN; wisselt pas als deze verbinding stopt, zodat de stream niet hapert.',
  flow_candidate_help:'Wordt beoordeeld; gaat naar de VPN als het genoeg verkeer blijft geven.', flow_watch_help:'Niet geleerd; loopt via WAN.',
  flow_fixed_route_help:'Al geregeld door VPN Director of een andere VPN Routing-policy; wordt niet geleerd.', flow_fixed_device_help:'Dit apparaat wordt volledig door VPN Director gerouteerd.',
  flow_excluded_range_help:'Valt onder je uitsluitingen; blijft via WAN.', flow_router_help:'Verkeer van de router zelf (updates, Skynet, AdGuardHome); wordt nooit geleerd.', flow_local_help:'Bestemming in je eigen netwerk.',
  presetPartHint:'Niet alle domeinen staan aan (bijv. nieuw toegevoegd na een update). Vink aan om alles uit te sluiten.',
  defaultValue:'Standaard', yourValue:'Jouw waarde',
  destName:'Naam', learnedHow:'Hoe geleerd', nameUnknown:'onbekend',
  nameKind_dns:'DNS-naam die een apparaat opvroeg', nameKind_host:'Hostnaam waarmee dit IP is geleerd', nameKind_ptr:'Omgekeerde DNS (PTR) - naam van de eigenaar van het IP, niet altijd de dienst',
  originAfterIdle:'Na einde stream (wachtlijst)', originFlow:'Streamscan · {dev} · poort {port} · {total}', originPromoted:'Genoeg verkeer na beoordeling', originImmediate:'Direct toegevoegd',
  originRedirect:'HTTP-doorverwijzing naar IP', originHost:'Hostnaam: {host}',
  helpFixed:'Alles wat je zelf al vast routeert, laat IP Catcher met rust: bestemmingen en apparaten uit VPN Director (VPN- én WAN-regels) en de domeinen en IP’s van je andere VPN Routing-policies. Die regels bepalen zelf al VPN of WAN. Ze worden elke minuut opnieuw ingelezen.'
});
Object.assign(VPNIPC_I18N.en,{
  subtitle:'IPTV streams automatically via the VPN, all other traffic via the WAN',
  fixedRoutes:'Fixed routes', fixedRoutesHint:'VPN Director / VPN Routing, never learned', waitingShort:'waiting',
  fixedMetaText:'{dst} destinations · {dev} devices · {pol} policies', fixedDestinations:'VPN Director destinations', fixedDevices:'VPN Director devices', fixedPolicies:'VPN Routing policies', none:'none',
  waitingExplain:'{count} IPs ready for the VPN; they switch only after the running stream stops',
  sourceAlert:'IP Catcher is watching all devices. Choose your IPTV box or TV as source device so other traffic can never end up on the VPN by accident.',
  chooseDevices:'Choose IPTV devices', devicePickerClear:'All devices', devicePickerEmpty:'No online devices found.', devicePickerOffline:'offline',
  devicePickerSelected:'{count} device(s) selected - save afterwards', devicePickerChanged:'Source devices changed - remember Save + restart',
  amtmAutoUpdate:'Automatic updates via amtm:', advancedDanger:'Advanced (overwrites settings)',
  flowStatus:'Status', filterWaiting:'Waiting', filterFixed:'Fixed route', filterRouter:'Router / local',
  flow_final:'via VPN', flow_waiting:'waits for stream end', flow_candidate:'under review', flow_watch:'via WAN',
  flow_fixed_route:'fixed route', flow_fixed_device:'fixed device', flow_excluded_range:'excluded', flow_router:'router itself', flow_local:'local',
  flow_final_help:'Destination is in the VPN list.', flow_waiting_help:'Ready for the VPN; switches only when this connection ends so the stream does not stall.',
  flow_candidate_help:'Under review; moves to the VPN if it keeps carrying enough traffic.', flow_watch_help:'Not learned; uses the WAN.',
  flow_fixed_route_help:'Already handled by VPN Director or another VPN Routing policy; not learned.', flow_fixed_device_help:'This device is routed completely by VPN Director.',
  flow_excluded_range_help:'Matches your exclusions; stays on the WAN.', flow_router_help:'Traffic of the router itself (updates, Skynet, AdGuardHome); never learned.', flow_local_help:'Destination in your own network.',
  presetPartHint:'Not all domains are enabled (for example added by an update). Tick to exclude everything.',
  defaultValue:'Default', yourValue:'Your value',
  destName:'Name', learnedHow:'How learned', nameUnknown:'unknown',
  nameKind_dns:'DNS name a device looked up', nameKind_host:'Hostname this IP was learned with', nameKind_ptr:'Reverse DNS (PTR) - name of the IP owner, not always the service',
  originAfterIdle:'After stream ended (waiting list)', originFlow:'Stream scan · {dev} · port {port} · {total}', originPromoted:'Enough traffic after review', originImmediate:'Added immediately',
  originRedirect:'HTTP redirect to IP', originHost:'Hostname: {host}',
  helpFixed:'Anything you already route yourself is left alone: destinations and devices from VPN Director (VPN and WAN rules) and the domains and IPs of your other VPN Routing policies. Those rules already decide VPN or WAN. They are re-read every minute.'
});
var FLOW_STATE_CLASS={final:'final',waiting:'waiting',candidate:'candidate','fixed-route':'fixed','fixed-device':'fixed','excluded-range':'excluded',router:'router',local:'local',watch:''};
function flowStateCell(r){
  var hint=r.hint||'watch', cls=FLOW_STATE_CLASS.hasOwnProperty(hint)?FLOW_STATE_CLASS[hint]:'';
  var key='flow_'+hint.replace(/-/g,'_'), label=VPNIPC_I18N[vpnipcCurrentLanguage]&&VPNIPC_I18N[vpnipcCurrentLanguage][key]?t(key):hint;
  return '<td data-sort="'+escapeHtml(hint)+'"><span class="flowState '+cls+'" title="'+escapeHtml(t(key+'_help')===key+'_help'?'':t(key+'_help'))+'">'+escapeHtml(label)+'</span></td>';
}
/* Destination names: DNS name a device received, the hostname an IP was
   learned with, or reverse DNS. Provided by the router as destination_names. */
function destinationName(ip){
  var names=(dataCache&&dataCache.destination_names)||{}, entry=names[ip];
  return entry&&entry.n?entry.n:'';
}
function destinationKind(ip){
  var names=(dataCache&&dataCache.destination_names)||{}, entry=names[ip];
  return entry?entry.k:'';
}
function nameCell(ip){
  var name=destinationName(ip), kind=destinationKind(ip);
  if(!name) return '<td class="muted">'+escapeHtml(t('nameUnknown'))+'</td>';
  return '<td title="'+escapeHtml(t('nameKind_'+kind))+'">'+escapeHtml(name)+(kind==='ptr'?' <span class="muted">(PTR)</span>':'')+'</td>';
}
function destinationCell(ip){
  var name=destinationName(ip);
  if(!name) return td(ip,'mono');
  return '<td class="mono" data-sort="'+escapeHtml(ip)+'" title="'+escapeHtml(t('nameKind_'+destinationKind(ip)))+'"><span class="deviceTag">'+escapeHtml(name)+'</span>'+escapeHtml(ip)+'</td>';
}
function deviceName(ip){
  var match=sourceDevices.filter(function(d){return d.ip===ip;})[0];
  return match&&match.name!==ip?match.name:ip;
}
/* Turn an ipset comment ("how was this IP found") into readable text. */
function describeOrigin(src){
  src=String(src||'');
  var m;
  if((m=src.match(/^after-idle:(.*)$/))) return t('originAfterIdle')+(m[1]&&m[1]!=='unknown'?' · '+describeOrigin(m[1]):'');
  if(/^[wp]romoted-after-idle$/.test(src)) return t('originAfterIdle');
  if((m=src.match(/^flow-delta(\d+)b-total(\d+)b-(\d+\.\d+\.\d+\.\d+)-(\d+)$/))) return t('originFlow',{dev:deviceName(m[3]),port:m[4],total:formatFlowBytes(m[2])});
  if(/^[wp]romoted-(bytes|age)$/.test(src)) return t('originPromoted');
  if(/^[wp]romoted-immediate$/.test(src)) return t('originImmediate');
  if(src==='http-location') return t('originRedirect');
  if(/^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(src)&&/[a-z]/.test(src)) return t('originHost',{host:src});
  return src||'-';
}
function sourceCell(ip){
  var match=sourceDevices.filter(function(d){return d.ip===ip&&d.name!==ip;})[0];
  if(!match) return td(ip,'mono');
  return '<td class="mono" data-sort="'+escapeHtml(ip)+'"><span class="deviceTag">'+escapeHtml(match.name)+'</span>'+escapeHtml(ip)+'</td>';
}
function fixedRoutesText(f){
  var parts=[];
  parts.push(t('fixedDestinations')+': '+(f.destinations||0)+(f.destination_list?' ('+f.destination_list+')':''));
  parts.push(t('fixedDevices')+': '+(f.devices||0)+(f.device_list?' ('+f.device_list+')':''));
  parts.push(t('fixedPolicies')+': '+(f.policies||t('none'))+(Number(f.domains)?' · '+f.domains+' '+t('domainsCount'):''));
  return parts.join(' · ');
}
function updateDefaultsTable(cfg){
  var table=byId('defaultsTable'); if(!table||!table.querySelectorAll) return;
  table.querySelectorAll('tr[data-keys]').forEach(function(row){
    var keys=row.getAttribute('data-keys').split(' '), unit=row.getAttribute('data-unit');
    var values=keys.map(function(k){var v=cfg[k]; return (v===undefined||v==='')?'-':v;});
    var text=values.join(' / ')+(unit&&values[0]!=='-'?' '+unit:'');
    if(keys[0]==='SOURCE_IPS') text=cfg.SOURCE_IPS?sourceDeviceLabel(cfg.SOURCE_IPS):t('allDevices');
    var cell=row.querySelector('.current'); if(cell) cell.textContent=text;
  });
}
/* Source device picker: choose IPTV boxes from the ASUS client list instead of typing IPs. */
var sourceDevices=[], sourceDevicesLoaded=false, sourceDevicesBusy=false;
function sourceDeviceLabel(ips){
  return getWords(ips).map(function(ip){
    var match=sourceDevices.filter(function(d){return d.ip===ip;})[0];
    return match&&match.name!==ip?match.name+' ('+ip+')':ip;
  }).join(', ');
}
function setupDevicePicker(){
  var input=byId('cfg_SOURCE_IPS'); if(!input||!input.parentNode||byId('devicePickerRow')) return;
  var row=document.createElement('div'); row.id='devicePickerRow'; row.className='fieldCell'; row.style.gridColumn='1 / -1';
  row.innerHTML='<div class="actions"><button type="button" class="btn small blue" onclick="toggleDevicePicker()" data-i18n="chooseDevices">'+escapeHtml(t('chooseDevices'))+'</button>'+
    '<button type="button" class="btn small" onclick="clearSourceDevices()" data-i18n="devicePickerClear">'+escapeHtml(t('devicePickerClear'))+'</button>'+
    '<span id="devicePickerStatus" class="muted"></span></div><div id="devicePicker" class="devicePicker" hidden></div>';
  input.parentNode.insertBefore(row,input.nextSibling);
}
function openDevicePicker(){
  setPage('config');
  var picker=byId('devicePicker'); if(picker) picker.hidden=false;
  loadSourceDevices();
  var field=byId('cfg_SOURCE_IPS'); if(field&&field.scrollIntoView) field.scrollIntoView({block:'center'});
}
function toggleDevicePicker(){
  var picker=byId('devicePicker'); if(!picker) return;
  picker.hidden=!picker.hidden;
  if(!picker.hidden) loadSourceDevices();
}
function renderDevicePicker(){
  var picker=byId('devicePicker'); if(!picker) return;
  var selected=getWords(byId('cfg_SOURCE_IPS').value), known={}, list=sourceDevices.slice();
  list.forEach(function(d){known[d.ip]=1;});
  selected.forEach(function(ip){ if(!known[ip]) list.push({ip:ip,name:t('devicePickerOffline')}); });
  if(!list.length){ picker.innerHTML='<div class="deviceRow muted">'+escapeHtml(t('devicePickerEmpty'))+'</div>'; return; }
  picker.innerHTML=list.map(function(d){
    var on=selected.indexOf(d.ip)>=0;
    return '<label class="deviceRow"><input type="checkbox" data-ip="'+escapeHtml(d.ip)+'" '+(on?'checked ':'')+'onchange="toggleSourceDevice(this)"><span class="deviceName">'+escapeHtml(d.name)+'</span><span class="deviceIp">'+escapeHtml(d.ip)+'</span></label>';
  }).join('');
  setText('devicePickerStatus', selected.length ? t('devicePickerSelected',{count:selected.length}) : t('emptyAllDevices'));
}
function toggleSourceDevice(el){
  var ip=el.getAttribute('data-ip'), field=byId('cfg_SOURCE_IPS');
  if(!/^\d{1,3}(\.\d{1,3}){3}$/.test(ip)) return;
  field.value=el.checked?mergeUnique(field.value,[ip]):removeWords(field.value,[ip]);
  dirty=true; renderPresets(); renderDevicePicker();
  showToast(t('devicePickerChanged'));
}
function clearSourceDevices(){
  var field=byId('cfg_SOURCE_IPS'); if(!field||!field.value) return;
  field.value=''; dirty=true; renderPresets(); renderDevicePicker();
}
function loadSourceDevices(){
  if(sourceDevicesBusy) return;
  sourceDevicesBusy=true; setText('devicePickerStatus',t('diagnosticLoading'));
  fetch('/appGet.cgi?hook=get_clientlist()',{credentials:'same-origin',cache:'no-store'}).then(function(r){if(!r.ok)throw new Error('HTTP '+r.status);return r.json();}).then(function(data){
    sourceDevices=diagnosticDevices(data&&data.get_clientlist); sourceDevicesLoaded=true; renderDevicePicker();
    if(dataCache) updateOverview(dataCache);
  }).catch(function(){ setText('devicePickerStatus',t('diagnosticClientsFailed')); renderDevicePicker(); }).finally(function(){sourceDevicesBusy=false;});
}
function updateOverview(d){
  setText('addonVersion',d.version||'-');
  var connection=d.vpn_connection||'', match=connection.match(/^(ovpnc|wgc)([1-5])$/);
  setText('selectedVpn',match?(match[1]==='ovpnc'?'OpenVPN ':'WireGuard ')+match[2]:'-');
  setText('selectedList',d.ipset_name||'');
  badge(d.engine); setText('lastUpdate',d.last_update); setText('enginePid',d.engine_pid); setText('tcpdumpCount',d.tcpdump_count); setText('candidateCount',d.candidate_count); setText('finalCount',d.final_count); setText('resolvedCount',d.resolved_count); setText('excludeNetCount',d.exclude_net_count); setText('excludeNetSet',d.exclude_net_set); setText('ipsetName',d.ipset_name);
  setText('overviewEngineState', d.engine==='running' ? t('serviceRunning') : t('serviceStopped'));
    setText('overviewCapture', 'tcpdump: '+(d.tcpdump_count||'-')+' - '+t('updated')+': '+(d.last_update||'-'));
  var sourceIps=(d.config && d.config.SOURCE_IPS) ? d.config.SOURCE_IPS : '';
  setText('overviewSourceIps', sourceIps ? sourceDeviceLabel(sourceIps) : t('allDevices'));
  var alertBar=byId('sourceAlert'); if(alertBar) alertBar.hidden=!!sourceIps || !d.config;
  setText('waitingCount', d.waiting_count||'0');
  setText('overviewWaiting', t('waitingExplain',{count:d.waiting_count||'0'}));
  var fixed=d.fixed_routes||{}, fixedTotal=(Number(fixed.destinations)||0)+(Number(fixed.devices)||0)+String(fixed.policies||'').split(/\s+/).filter(Boolean).length;
  setText('fixedCount', d.fixed_routes ? fixedTotal : '-');
  setText('fixedMeta', d.fixed_routes ? t('fixedMetaText',{dst:fixed.destinations||0,dev:fixed.devices||0,pol:String(fixed.policies||'').split(/\s+/).filter(Boolean).length}) : t('fixedRoutesHint'));
  setText('overviewFixed', d.fixed_routes ? fixedRoutesText(fixed) : '-');
  setText('footerVersion', d.version||'-');
  updateDefaultsTable(d.config||{});
  var select=byId('dvrPolicy');
  if(select){
    var value=select.value,options='<option value="">'+escapeHtml(t('dvrChoose'))+'</option>';
    String(d.dvr_policies||'').split('\n').forEach(function(line){var p=line.split('|');if(/^[A-Za-z0-9_-]{1,24}$/.test(p[0])&&/^(ovpnc|wgc)[1-5]$/.test(p[1]))options+='<option value="'+escapeHtml(p[0])+'">'+escapeHtml(p[0]+' · '+p[1])+'</option>';});
    if(select.innerHTML!==options){select.innerHTML=options;select.value=value;}
  }
  setText('diagnosticDnsState',t('dnsState_'+(d.diagnostic_dns_state||'unavailable').replace(/-/g,'_')));
  setText('autoUpdateStatus',t(d.amtmupdate_enabled==='yes'?'autoUpdateOn':'autoUpdateOff'));
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
function togglePresetPart(el){
  var item=findPreset(el.getAttribute('data-key')),kind=el.getAttribute('data-kind'),value=el.getAttribute('data-value');
  if(!item||['domains','ips','nets'].indexOf(kind)<0||(item[kind]||[]).indexOf(value)<0)return;
  if(kind==='ips'&&(protectedPresetIps||[]).indexOf(value)>=0)return;
  var part={key:item.key,label:item.label,domains:[],ips:[],nets:[]};part[kind]=[value];
  applyPresetToConfig(part,el.checked?'add':'remove');
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
  var openDetails={};wrap.querySelectorAll('details[open][data-preset]').forEach(function(el){openDetails[el.getAttribute('data-preset')]=true;});
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
      if(state==='PART' && !pending) html+='<div class="presetMeta statusPart">'+escapeHtml(t('presetPartHint'))+'</div>';
      html+='<details data-preset="'+escapeHtml(item.key)+'" '+(openDetails[item.key]?'open':'')+'><summary>'+escapeHtml(t('choosePresetItems'))+'</summary><div class="presetMeta">';
      ['domains','ips','nets'].forEach(function(kind){
        var field=byId('cfg_EXCLUDE_'+(kind==='domains'?'DOMAINS':kind==='ips'?'IPS':'NETS'));
        var selected=getWords(field.value);
        (item[kind]||[]).forEach(function(value){
          var protectedValue=kind==='ips'&&(protectedPresetIps||[]).indexOf(value)>=0;
          html+='<label style="display:flex;gap:8px;margin:6px 0"><input type="checkbox" data-key="'+escapeHtml(item.key)+'" data-kind="'+kind+'" data-value="'+escapeHtml(value)+'" '+(protectedValue||selected.indexOf(value)>=0?'checked ':'')+(protectedValue?'disabled ':'')+'onchange="togglePresetPart(this)"><span>'+escapeHtml(value)+'</span></label>';
        });
      });
      html+='</div></details>';
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
  setupDevicePicker();
  vpnipcInitLanguage();
  document.querySelectorAll('.vpn_ipcatcher_dashboard [id^="cfg_"]').forEach(function(e){ e.addEventListener('input', function(){ dirty=true; updateExclusionPreview(); renderPresets(); }); });
  setPage('overview'); setTab('flows'); loadPresets(); loadStatus(); loadSourceDevices(); setInterval(function(){ if(!actionBusy){if(currentPage==='live'&&currentTab==='diagnostic')refreshDiagnostic();loadStatus();} }, 5000);
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
                  <div class="subtitle" data-i18n="subtitle">IPTV-streams automatisch via de VPN, al het andere verkeer via WAN</div>
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
                  <div class="card accent"><h3 data-i18n="engine">Engine</h3><div><span id="engineBadge" class="badge warn" data-i18n="loading">LADEN</span></div><div class="muted">PID: <span id="enginePid">-</span></div></div>
                  <div class="card good"><h3 data-i18n="finalIps">Definitieve IP’s</h3><div class="big" id="finalCount">-</div><div class="muted" id="ipsetName">-</div></div>
                  <div class="card attention"><h3 data-i18n="candidateIps">Kandidaat-IP’s</h3><div class="big" id="candidateCount">-</div><div class="muted"><span data-i18n="waitingShort">wachtlijst</span>: <strong id="waitingCount">-</strong></div></div>
                  <div class="card"><h3 data-i18n="excludeCache">Uitsluitcache</h3><div class="big" id="resolvedCount">-</div><div class="muted" data-i18n="excludeCacheHint">tijdelijk opgeloste domein-IP’s</div></div>
                  <div class="card"><h3 data-i18n="excludeRanges">Uitsluitbereiken</h3><div class="big" id="excludeNetCount">-</div><div class="muted" id="excludeNetSet" data-default-i18n="fixedRanges">vaste CIDR-bereiken</div></div>
                  <div class="card violet"><h3 data-i18n="fixedRoutes">Vaste routes</h3><div class="big" id="fixedCount">-</div><div class="muted" id="fixedMeta">VPN Director / VPN Routing, nooit geleerd</div></div>
                </div>
                <div class="alertBar" id="sourceAlert" hidden><span data-i18n="sourceAlert">IP Catcher kijkt nu naar alle apparaten. Kies je IPTV-box of tv als bronapparaat, dan kan ander verkeer nooit per ongeluk via de VPN gaan.</span><button type="button" class="btn blue" onclick="openDevicePicker()" data-i18n="chooseDevices">IPTV-apparaten kiezen</button></div>
                <div class="muted" style="margin:-4px 0 8px 2px">tcpdump: <span id="tcpdumpCount">-</span> - <span data-i18n="updated">bijgewerkt</span>: <span id="lastUpdate">-</span></div>

                <div class="panel">
                  <div class="panel-title"><span data-i18n="actions">Acties</span> <span id="toast" class="muted"></span></div>
                  <div class="panel-body actions">
                    <button type="button" class="btn green" onclick="applyAction('start')" data-i18n="start">Start</button>
                    <button type="button" class="btn red" onclick="applyAction('stop')" data-i18n="stop">Stop</button>
                    <button type="button" class="btn orange" onclick="applyAction('restart')" data-i18n="restart">Herstarten</button>
                    <button type="button" class="btn blue" onclick="applyAction('publish')" data-i18n="refreshStatus">Status vernieuwen</button>
                  </div>
                  <details class="maintenance"><summary data-i18n="maintenance">Onderhoud</summary>
                    <div class="actions">
                      <button type="button" class="btn" onclick="applyAction('check_update')" data-i18n="checkUpdate">Update controleren</button>
                      <button type="button" class="btn blue" onclick="applyAction('install_update')" data-i18n="installUpdate">Update installeren</button>
                      <button type="button" class="btn" onclick="applyAction('resolve_excludes')" data-i18n="resolveExcludes">Uitsluitingen oplossen</button>
                      <button type="button" class="btn" onclick="applyAction('clean_excluded')" data-i18n="cleanExcludedIps">Uitgesloten IP’s opruimen</button>
                      <button type="button" class="btn" onclick="applyAction('clear_log')" data-i18n="clearLog">Log wissen</button>
                      <progress id="maintenanceProgress" hidden></progress>
                    </div>
                    <div class="actions" style="margin-top:8px">
                      <span class="muted" data-i18n="amtmAutoUpdate">Automatische updates via amtm:</span>
                      <button type="button" class="btn small" onclick="applyAction('auto_update_enable')" data-i18n="autoUpdateEnable">amtm-updates toestaan</button>
                      <button type="button" class="btn small" onclick="applyAction('auto_update_disable')" data-i18n="autoUpdateDisable">amtm-updates uitschakelen</button>
                      <span id="autoUpdateStatus" role="status" class="muted"></span>
                    </div>
                    <details class="danger-zone"><summary data-i18n="advancedDanger">Geavanceerd (overschrijft instellingen)</summary>
                      <div class="actions">
                        <button type="button" class="btn danger" onclick="applyAction('safe_excludes')" data-i18n="safeBaseExcludes">Veilige basisuitsluitingen</button>
                        <button type="button" class="btn danger" onclick="applyAction('repair_excludes')" data-i18n="repairSafeExcludes">Veilige uitsluitingen herstellen</button>
                        <button type="button" class="btn danger" onclick="applyAction('force_update')" data-i18n="forceUpdate">Opnieuw installeren</button>
                      </div>
                    </details>
                    <p id="maintenanceResult" role="status"></p>
                  </details>
                </div>

                <div class="layoutTabs">
                  <button type="button" class="layoutTab active" id="pageTab_overview" onclick="setPage('overview')" data-i18n="overview">Overview</button>
                  <button type="button" class="layoutTab" id="pageTab_live" onclick="setPage('live')" data-i18n="liveView">Live view</button>
                  <button type="button" class="layoutTab" id="pageTab_config" onclick="setPage('config')" data-i18n="config">Config</button>
                  <button type="button" class="layoutTab" id="pageTab_exclusions" onclick="setPage('exclusions')" data-i18n="exclusions">Exclusions</button>
                  <button type="button" class="layoutTab" id="pageTab_presets" onclick="setPage('presets')" data-i18n="presetLists">Preset lists</button>
                  <button type="button" class="layoutTab" id="pageTab_routing" onclick="setPage('routing')" data-i18n="routing">Domeinroutes</button>
                  <button type="button" class="layoutTab" id="pageTab_help" onclick="setPage('help')" data-i18n="help">Uitleg</button>
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
                          <tr><th data-i18n="sourceIps">Bron-IP’s</th><td><span id="overviewSourceIps">-</span> <button type="button" class="btn small" onclick="openDevicePicker()" data-i18n="chooseDevices">IPTV-apparaten kiezen</button></td></tr>
                          <tr><th data-i18n="waiting">Wachtlijst</th><td id="overviewWaiting">-</td></tr>
                          <tr><th data-i18n="fixedRoutes">Vaste routes</th><td id="overviewFixed">-</td></tr>
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
                        <span id="diagnosticDnsState" class="muted" role="status"></span>
                        <span class="muted" data-i18n="diagnosticLimited">Laatste 2000 waarnemingen; export bevat privé-verbindingsgegevens.</span>
                      </div>
                      <div id="liveFilters" class="liveFilters">
                        <label><span data-i18n="filterSearch">Zoeken</span><input type="search" id="liveSearch" oninput="renderLiveTab()"></label>
                        <div id="flowControls">
                          <label><span data-i18n="filterSource">Bronapparaat</span><select id="flowSource" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option></select></label>
                          <label><span data-i18n="filterPort">Poort</span><select id="flowPort" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option></select></label>
                          <label><span data-i18n="filterState">Lijststatus</span><select id="flowState" onchange="renderLiveTab()"><option value="" data-i18n="filterAll">Alles</option><option value="final" data-i18n="filterFinal">Definitieve lijst</option><option value="candidate" data-i18n="filterCandidate">Kandidaat</option><option value="waiting" data-i18n="filterWaiting">Wachtlijst</option><option value="fixed" data-i18n="filterFixed">Vaste route</option><option value="excluded" data-i18n="filterExcluded">Uitgesloten</option><option value="router" data-i18n="filterRouter">Router / lokaal</option><option value="other" data-i18n="filterOther">Overige</option></select></label>
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
                        <label>Eigen provider-netwerken automatisch ophalen (RIPE, dagelijks)</label><select id="cfg_PROVIDER_RANGE_AUTO"><option value="yes" data-i18n="yes">ja</option><option value="no" data-i18n="no">nee</option></select>
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

                <div class="page" id="page_routing">
                  <div class="panel-title" data-i18n="routing">Domeinroutes</div>
                  <div class="panel-body">
                    <div class="liveFilters">
                      <label><span data-i18n="dvrDomain">EPG URL / hostnaam</span><input id="dvrDomain" maxlength="2048" placeholder="https://epg.example.com/guide.xml.gz" autocapitalize="none" spellcheck="false"></label>
                      <label><span data-i18n="dvrChoose">Kies bestaande DVR-policy</span><select id="dvrPolicy"></select></label>
                      <button type="button" class="btn blue" onclick="addDvrDomain()" data-i18n="dvrAdd">Altijd via VPN instellen</button>
                    </div>
                    <p id="dvrResult" role="status"></p>
                    <p class="muted" data-i18n="forceVpnHelp">Een volledige EPG-URL mag: alleen de hostnaam wordt via de gekozen VPN gerouteerd. Deze handmatige policy gaat vóór de automatische IPTV-lijst; gedeelde CDN-IP's en DoH kunnen niet per URL-pad worden onderscheiden.</p><p class="muted" data-i18n="helpRouting"></p>
                  </div>
                </div>
                <div class="page" id="page_help">
                  <div class="panel-title" data-i18n="help">Uitleg</div>
                  <div class="panel-body">
                    <h3 data-i18n="defaultsTitle">Standaardwaarden</h3>
                    <p data-i18n="defaultsExplain"></p>
                    <p data-i18n="promotionExplain"></p>
                    <table class="data" id="defaultsTable"><thead><tr><th data-i18n="field">Veld</th><th data-i18n="defaultValue">Standaard</th><th data-i18n="yourValue">Jouw waarde</th></tr></thead><tbody>
                      <tr data-keys="PROMOTE_MODE"><td data-i18n="promoteMode">Promotiemodus</td><td>auto</td><td class="current">-</td></tr>
                      <tr data-keys="PROMOTE_EVERY" data-unit="s"><td data-i18n="promoteInterval">Promotie-interval</td><td>15 s</td><td class="current">-</td></tr>
                      <tr data-keys="MIN_AGE" data-unit="s"><td data-i18n="minAge">Minimale leeftijd</td><td>30 s</td><td class="current">-</td></tr>
                      <tr data-keys="CANDIDATE_TIMEOUT" data-unit="s"><td data-i18n="candidateTimeout">Kandidaat-time-out</td><td>600 s (10 min)</td><td class="current">-</td></tr>
                      <tr data-keys="FINAL_TIMEOUT" data-unit="s"><td data-i18n="finalTimeout">Definitieve time-out</td><td>604800 s (7 d)</td><td class="current">-</td></tr>
                      <tr data-keys="STREAM_FLOW_SCAN STREAM_FLOW_TARGET"><td>STREAM_FLOW_SCAN / STREAM_FLOW_TARGET</td><td>yes / candidate</td><td class="current">-</td></tr>
                      <tr data-keys="STREAM_SCAN_EVERY" data-unit="s"><td>STREAM_SCAN_EVERY</td><td>5 s</td><td class="current">-</td></tr>
                      <tr data-keys="MIN_BYTES STREAM_MIN_BYTES"><td>MIN_BYTES / STREAM_MIN_BYTES</td><td>1000000 / 15000000 B</td><td class="current">-</td></tr>
                      <tr data-keys="STREAM_MIN_DELTA STREAM_REQUIRE_GROWTH"><td>STREAM_MIN_DELTA / STREAM_REQUIRE_GROWTH</td><td>750000 B / yes</td><td class="current">-</td></tr>
                      <tr data-keys="EXCLUDE_RESOLVE_CACHE EXCLUDE_RESOLVE_EVERY"><td>EXCLUDE_RESOLVE_CACHE / EXCLUDE_RESOLVE_EVERY</td><td>yes / 3600 s</td><td class="current">-</td></tr>
                      <tr data-keys="REVERSE_DNS_CHECK CAPTURE_GENERIC_HOSTNAMES ALLOW_EXTERNAL_DNS"><td>REVERSE_DNS_CHECK / CAPTURE_GENERIC_HOSTNAMES / ALLOW_EXTERNAL_DNS</td><td>no / no / no</td><td class="current">-</td></tr>
                      <tr data-keys="SOURCE_IPS"><td data-i18n="sourceIpsLabel">Bron-IP’s</td><td data-i18n="emptyAllDevices">leeg = alle apparaten</td><td class="current">-</td></tr>
                    </tbody></table>
                    <p data-i18n="defaultsAdvice"></p>
                    <h3 data-i18n="fixedRoutes">Vaste routes</h3><p data-i18n="helpFixed"></p>
                    <h3 data-i18n="candidate">Kandidaat</h3><p data-i18n="helpLists"></p>
                    <h3 data-i18n="routing">Domeinroutes</h3><p data-i18n="helpRouting"></p>
                    <h3 data-i18n="presetLists">Presetlijsten</h3><p data-i18n="helpPresets"></p>
                    <h3 data-i18n="diagnostic">Diagnose</h3><p data-i18n="helpDns"></p>
                    <h3 data-i18n="maintenance">Onderhoud</h3><p data-i18n="helpUpdates"></p>
                  </div>
                </div>
                <div class="footer">VPN IP Catcher <span id="footerVersion">-</span> · Asuswrt-Merlin</div>
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
