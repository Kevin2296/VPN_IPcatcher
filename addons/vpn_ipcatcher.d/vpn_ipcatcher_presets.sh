#!/bin/sh
# Shared preset registry for vpn_ipcatcher (amtm + WebGUI)
# Fast case-based implementation for low-power router CPUs.
VPNIPC_PRESET_SCHEMA="2"
VPNIPC_SYSTEM_EXCLUDE_IPS="1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220"

preset_domains(){
  case "$1" in
    dns_cloudflare) echo "one.one.one.one cloudflare-dns.com" ;;
    dns_quad9) echo "quad9.net" ;;
    dns_google) echo "dns.google" ;;
    dns_opendns) echo "opendns.com" ;;
    social_meta) echo "facebook.com www.facebook.com graph.facebook.com fbcdn.net fbsbx.com mqtt-mini.facebook.com edge-mqtt.facebook.com gateway.facebook.com" ;;
    social_whatsapp) echo "whatsapp.com web.whatsapp.com static.whatsapp.net mmg.whatsapp.net media.whatsapp.net" ;;
    social_instagram) echo "instagram.com www.instagram.com cdninstagram.com i.instagram.com" ;;
    social_snapchat) echo "snapchat.com app.snapchat.com sc-analytics.appspot.com feelinsonice.appspot.com" ;;
    cam_eufy) echo "eufylife.com security-app.eufylife.com eufy.com anker.com anker-in.com" ;;
    cam_dahua_imou) echo "imoulife.com easy4ip.com lechange.com dahuasecurity.com dahuatech.com dahua2w.com dahuap2p.com" ;;
    dev_github) echo "github.com api.github.com githubusercontent.com githubassets.com github.io raw.githubusercontent.com objects.githubusercontent.com" ;;
    game_steam) echo "steamcontent.com steampowered.com steamstatic.com steamserver.net" ;;
    game_epic) echo "epicgames.com epicgamescdn.com unrealengine.com" ;;
    game_xbox) echo "xboxlive.com xboxservices.com xbox.com xsts.auth.xboxlive.com" ;;
    game_playstation) echo "playstation.net playstation.com sonyentertainmentnetwork.com" ;;
    game_nintendo) echo "nintendo.net nintendo.com nintendo-europe.com" ;;
    game_battlenet) echo "battle.net blizzard.com blzstatic.com blizzardgearstore.com" ;;
    upd_windows) echo "windowsupdate.com update.microsoft.com delivery.mp.microsoft.com download.windowsupdate.com wustat.windows.com" ;;
    upd_msstore) echo "storeedgefd.dsx.mp.microsoft.com dl.delivery.mp.microsoft.com displaycatalog.mp.microsoft.com" ;;
    upd_office) echo "officecdn.microsoft.com office.com office365.com microsoft.com msedge.net azureedge.net" ;;
    upd_apple) echo "apple.com icloud.com mzstatic.com aaplimg.com apple-dns.net appldnld.apple.com swcdn.apple.com" ;;
    upd_google) echo "googleapis.com gvt1.com gvt2.com android.clients.google.com play.googleapis.com" ;;
    tv_samsung) echo "samsungcloudsolution.net samsungcloudsolution.com samsungacr.com samsung.com" ;;
    tv_philips) echo "philips.com tpv-tech.com philips-tvconsumercare.com" ;;
    tv_android) echo "androidtv.com android.com gstatic.com googleapis.com" ;;
    tv_lg) echo "lge.com lgsmartad.com lgtvcommon.com" ;;
    stream_netflix) echo "netflix.com www.netflix.com nflxvideo.net nflxso.net nflxext.com nflximg.net" ;;
    stream_youtube) echo "youtube.com googlevideo.com ytimg.com youtubei.googleapis.com" ;;
    stream_disney) echo "disneyplus.com disney-plus.net dssott.com bamgrid.com" ;;
    stream_prime) echo "primevideo.com amazonvideo.com aiv-cdn.net media-amazon.com" ;;
    stream_videoland) echo "videoland.com rtl.nl" ;;
    stream_viaplay) echo "viaplay.com viaplaycontent.com" ;;
    *) echo "" ;;
  esac
}

preset_ips(){
  case "$1" in
    dns_cloudflare) echo "1.1.1.1 1.0.0.1" ;;
    dns_quad9) echo "9.9.9.9 149.112.112.112" ;;
    dns_google) echo "8.8.8.8 8.8.4.4" ;;
    dns_opendns) echo "208.67.222.222 208.67.220.220" ;;
    *) echo "" ;;
  esac
}

preset_nets(){
  case "$1" in
    social_meta) echo "31.13.24.0/21 31.13.64.0/18 45.64.40.0/22 57.144.0.0/14 66.220.144.0/20 69.63.176.0/20 69.171.224.0/19 74.119.76.0/22 102.132.96.0/20 103.4.96.0/22 129.134.0.0/16 157.240.0.0/16 163.70.128.0/17 173.252.64.0/18 179.60.192.0/22 185.60.216.0/22 204.15.20.0/22" ;;
    social_whatsapp) echo "57.144.0.0/14" ;;
    social_instagram) echo "57.144.0.0/14 157.240.0.0/16" ;;
    *) echo "" ;;
  esac
}

preset_label(){
  case "$1" in
    dns_cloudflare) echo "Cloudflare DNS" ;;
    dns_quad9) echo "Quad9 DNS" ;;
    dns_google) echo "Google DNS" ;;
    dns_opendns) echo "OpenDNS" ;;
    social_meta) echo "Meta / Facebook" ;;
    social_whatsapp) echo "WhatsApp" ;;
    social_instagram) echo "Instagram" ;;
    social_snapchat) echo "Snapchat" ;;
    cam_eufy) echo "Eufy / Anker Security" ;;
    cam_dahua_imou) echo "Dahua / Imou / Easy4IP" ;;
    dev_github) echo "GitHub" ;;
    game_steam) echo "Steam" ;;
    game_epic) echo "Epic Games" ;;
    game_xbox) echo "Xbox / Game Pass" ;;
    game_playstation) echo "PlayStation" ;;
    game_nintendo) echo "Nintendo" ;;
    game_battlenet) echo "Battle.net / Blizzard" ;;
    upd_windows) echo "Windows Update" ;;
    upd_msstore) echo "Microsoft Store" ;;
    upd_office) echo "Office / Microsoft CDN" ;;
    upd_apple) echo "Apple / iCloud updates" ;;
    upd_google) echo "Google / Android updates" ;;
    tv_samsung) echo "Samsung Smart TV telemetry" ;;
    tv_philips) echo "Philips Smart TV telemetry" ;;
    tv_android) echo "Android TV telemetry" ;;
    tv_lg) echo "LG Smart TV telemetry" ;;
    stream_netflix) echo "Netflix" ;;
    stream_youtube) echo "YouTube" ;;
    stream_disney) echo "Disney+" ;;
    stream_prime) echo "Prime Video" ;;
    stream_videoland) echo "Videoland" ;;
    stream_viaplay) echo "Viaplay" ;;
    *) echo "$1" ;;
  esac
}

preset_keys_for_category(){
  case "$1" in
    "DNS providers") echo "dns_cloudflare dns_quad9 dns_google dns_opendns" ;;
    "Social / messaging") echo "social_meta social_whatsapp social_instagram social_snapchat" ;;
    "Security cameras / IoT cloud") echo "cam_eufy cam_dahua_imou" ;;
    "GitHub / dev CDN") echo "dev_github" ;;
    "Games / downloads") echo "game_steam game_epic game_xbox game_playstation game_nintendo game_battlenet" ;;
    "OS / app updates") echo "upd_windows upd_msstore upd_office upd_apple upd_google" ;;
    "Smart TV telemetry") echo "tv_samsung tv_philips tv_android tv_lg" ;;
    "Streamingdiensten") echo "stream_netflix stream_youtube stream_disney stream_prime stream_videoland stream_viaplay" ;;
    *) echo "" ;;
  esac
}

preset_categories(){
  cat <<'EOF_CATS'
DNS providers
Social / messaging
Security cameras / IoT cloud
GitHub / dev CDN
Games / downloads
OS / app updates
Smart TV telemetry
Streamingdiensten
EOF_CATS
}

preset_category_note(){
  case "$1" in
    "DNS providers") echo "Meestal uitsluiten zodat DNS-resolvers nooit via VPN Director worden geleerd." ;;
    "Social / messaging") echo "Voorkomt Meta, WhatsApp, Instagram en Snapchat als bijvangst." ;;
    "Security cameras / IoT cloud") echo "Camera- en IoT-cloudverkeer uitsluiten." ;;
    "GitHub / dev CDN") echo "Voorkomt dat GitHub/CDN-verkeer als stream wordt geleerd." ;;
    "Games / downloads") echo "Grote game-downloads niet als stream leren." ;;
    "OS / app updates") echo "Updates en software-CDN-verkeer uitsluiten." ;;
    "Smart TV telemetry") echo "Achtergrond- en telemetrieverkeer van smart-tv-platformen verminderen." ;;
    "Streamingdiensten") echo "Alleen inschakelen voor diensten die juist NIET via deze VPN-regel mogen." ;;
    *) echo "" ;;
  esac
}

preset_json_escape(){
  printf '%s' "$1" | ${AWK:-awk} '{gsub(/\\/,"\\\\"); gsub(/\"/,"\\\""); if(NR>1) printf "\\n"; printf "%s",$0}'
}

preset_json_array_words(){
  words="$1"; first=1; printf '['
  for word in $words; do
    [ "$first" = "1" ] || printf ','
    printf '"%s"' "$(preset_json_escape "$word")"
    first=0
  done
  printf ']'
}

preset_write_json(){
  target="$1"; [ -n "$target" ] || return 1
  tmp="${target}.$$"
  mkdir -p "$(dirname "$target")" 2>/dev/null
  {
    printf '{\n  "schema":"%s",\n' "$VPNIPC_PRESET_SCHEMA"
    printf '  "protected_ips":'; preset_json_array_words "$VPNIPC_SYSTEM_EXCLUDE_IPS"; printf ',\n'
    printf '  "categories":[\n'
    first_cat=1
    while IFS= read -r category; do
      [ -n "$category" ] || continue
      [ "$first_cat" = "1" ] || printf ',\n'
      first_cat=0
      printf '    {"name":"%s","note":"%s","items":[' "$(preset_json_escape "$category")" "$(preset_json_escape "$(preset_category_note "$category")")"
      first_item=1
      for key in $(preset_keys_for_category "$category"); do
        [ "$first_item" = "1" ] || printf ','
        first_item=0
        printf '{"key":"%s","label":"%s","domains":' "$(preset_json_escape "$key")" "$(preset_json_escape "$(preset_label "$key")")"
        preset_json_array_words "$(preset_domains "$key")"
        printf ',"ips":'; preset_json_array_words "$(preset_ips "$key")"
        printf ',"nets":'; preset_json_array_words "$(preset_nets "$key")"
        printf '}'
      done
      printf ']}'
    done <<EOF_CATEGORY_LIST
$(preset_categories)
EOF_CATEGORY_LIST
    printf '\n  ]\n}\n'
  } > "$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$target"
  chmod 644 "$target" 2>/dev/null
}
