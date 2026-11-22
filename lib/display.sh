# display: seeing the TV screen

cmd_screenshot() {
  local out=${1:-tv-$(date +%Y%m%d-%H%M%S).png}
  connect
  A shell screencap -p /sdcard/tv-shot.png && A pull /sdcard/tv-shot.png "$out" >/dev/null &&
    A shell rm /sdcard/tv-shot.png && echo "$out"
}

cmd_mirror() {
  command -v scrcpy >/dev/null || {
    echo "tv mirror: scrcpy not found (install it, e.g. 'sudo apt install scrcpy')" >&2
    exit 1
  }
  connect
  # lower res/bitrate: the TV has very little RAM and CPU headroom
  exec scrcpy -s "$IP:5555" --window-title "TV $IP" \
    --max-size 1280 --video-bit-rate 4M "$@"
}

register screenshot cmd_screenshot "[file]" "save a PNG of the screen" \
"Default file is ./tv-<timestamp>.png."
register mirror     cmd_mirror     "[scrcpy args]" "show/control the screen on this PC with scrcpy" \
"Extra arguments are passed straight to scrcpy, e.g. 'tv mirror --no-control'."
alias_cmd scrcpy mirror
