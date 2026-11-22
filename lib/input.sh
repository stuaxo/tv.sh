# input: remote-control keys, text, inputs and channels

declare -A KEYS=(
  [up]=19 [down]=20 [left]=21 [right]=22 [ok]=23 [enter]=66 [back]=4
  [home]=3 [menu]=82 [info]=165 [guide]=172 [power]=26 [wake]=224
  [sleep]=223 [play]=126 [pause]=127 [stop]=86 [playpause]=85
  [next]=87 [prev]=88 [ff]=90 [rew]=89 [mute]=164
  [volup]=24 [voldown]=25 [chup]=166 [chdown]=167
  [red]=183 [green]=184 [yellow]=185 [blue]=186
)

cmd_key() {
  local k=$1
  [[ -n $k ]] || { echo "tv key: missing key" >&2; exit 2; }
  local code=${KEYS[$k]:-$k}
  [[ $code =~ ^[0-9]+$ ]] || { echo "tv key: unknown key '$k'" >&2; exit 2; }
  send_key "$code"
}

cmd_home() { send_key 3; }   # KEYCODE_HOME
cmd_back() { send_key 4; }   # KEYCODE_BACK

cmd_text() {
  [[ -n $1 ]] || { echo "tv text: missing text" >&2; exit 2; }
  local t=${*// /%s}   # input text wants %s for spaces
  connect
  A shell input text "$t"
}

# input source name -> keycode
declare -A INPUTS=([tv]=170 [hdmi1]=243 [hdmi2]=244 [hdmi3]=245 [hdmi4]=246)

cmd_input() {
  local code=${INPUTS[$1]}
  [[ -n $code ]] || { echo "usage: tv input $(printf '%s|' $(printf '%s\n' "${!INPUTS[@]}" | sort))" | sed 's/|$//' >&2; exit 2; }
  send_key "$code"
}

cmd_inputs() {
  local all=0
  case $1 in
    '')    ;;
    --all) all=1 ;;
    *) echo "usage: tv inputs [--all]" >&2; exit 2 ;;
  esac
  if (( ! all )); then
    # what the TV's own input framework reports (output format varies by firmware)
    adb connect "$IP" >/dev/null 2>&1
    local found
    found=$(A shell dumpsys tv_input 2>/dev/null | tr -d '\r' |
      grep -iE 'inputId|input_id|hdmi|tuner|passthrough' | sed 's/^ */  /')
    if [[ -n $found ]]; then echo "$found"; return; fi
    echo "tv inputs: nothing from the TV, showing the inputs this script supports" >&2
  fi
  local n
  for n in $(printf '%s\n' "${!INPUTS[@]}" | sort); do
    printf '%-8s keycode %s\n' "$n" "${INPUTS[$n]}"
  done
}

cmd_channel() {
  case $1 in
    up)   send_key 166 ;;
    down) send_key 167 ;;
    ''|*[!0-9]*) echo "usage: tv channel up|down|<number>" >&2; exit 2 ;;
    *)
      connect
      local i
      for (( i=0; i<${#1}; i++ )); do A shell input keyevent $(( 7 + ${1:i:1} )); done
      A shell input keyevent 66
      ;;
  esac
}

register key     cmd_key     "<name|code>" "send any remote key" \
"Names: ${!KEYS[*]}
or a numeric Android keycode."
register home    cmd_home    ""                    "go to the home screen"
register back    cmd_back    ""                    "press the back button"
register text    cmd_text    '"<string>"'          "type text into the focused field"
register input   cmd_input   "<name>" "switch input source"
register inputs  cmd_inputs  "[--all]"             "list the TV's input sources" \
"Queries the TV (dumpsys tv_input) for the inputs it reports; best effort,
the format depends on the firmware.
  --all  list the inputs 'tv input' supports, without contacting the TV"
register channel cmd_channel "up|down|<number>"    "change TV channel"
alias_cmd ch channel
