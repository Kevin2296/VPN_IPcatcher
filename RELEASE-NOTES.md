# 🛡️ VPN IP Catcher 2.8.2 · Testrelease / Prerelease

**WebUI-fix:** tabs/controltekens in logregels breken de status-JSON niet meer.
**WebUI fix:** tabs/control characters in logs no longer invalidate status JSON.

🇳🇱 [Nederlandse uitleg](https://github.com/Kevin2296/VPN_IPcatcher#nederlands) · 🇬🇧 [English documentation](https://github.com/Kevin2296/VPN_IPcatcher#english)

## 🇳🇱 Nieuw

- 💾 Menu **24 · Maak back-up**: klein of uitgebreid, zonder los commando.
- 🔒 Automatische kleine privéback-up voor installatie/update; fout = update stopt.
- 🎛️ Menu **25 · Toevoegen aan amtm**: persoonlijke registratie, geen dubbele vermeldingen.
- 🧠 Automatische candidate/final/wait/exclude-lijsten; wachtlijst zichtbaar in de WebUI.
- 🔧 Reset van leerinstellingen behoudt de gekozen VPN/lijst en maakt eerst een back-up.
- 📚 Alle hoofdmenuopties uitgelegd, NL en EN op dezelfde repositorypagina.

Gebruik het installatie/updatecommando in de README. **Voor de overgang van
2.8.0 naar 2.8.1 of nieuwer gebruik je eenmaal het README-updatecommando**, zodat ook de
nieuwe helpers worden meegenomen. Daarna zijn menu-updates weer voldoende.
De downloads bevatten uitsluitend openbare code, documentatie en tests.
Privé-back-ups blijven op de router en horen nooit op GitHub.

## 🇬🇧 What's New

- 💾 Menu **24** creates a small/full private backup without a separate command.
- 🔒 Automatic small backup before install/update; backup failures stop the update.
- 🎛️ Menu **25** registers the addon as an amtm personal script without duplicates.
- 🧠 Automatic lists and a visible Waiting tab in the WebUI.
- 🔧 Learning-settings reset preserves the VPN/list binding and backs up first.
- 📚 Full main-menu overview, Dutch and English on the same repository page.

**Use the README update command once when upgrading 2.8.0 to 2.8.1 or newer**, to install
the newly added helpers. Future updates can use the menu. Downloads contain
public files only; private backups remain on your router.

## ⚠️ Status / Limitations

Local tests do not prove full RT-AX86U Pro / Merlin WebUI compatibility. Validate
on the router before treating this as stable. No VPN killswitch, no IPv6 learning,
and no guarantee against every streaming-site error. A first installation is not
fully transactional if interrupted. Archives are not full router/nvram backups.

The router archive includes runtime code, VERSION and SHA256SUMS. The source ZIP
also includes docs and tests. Prefer the verified installer over manual extraction.
