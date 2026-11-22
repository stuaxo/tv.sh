# info: querying the TV's state

cmd_now() {
  connect
  A shell dumpsys window | tr -d '\r' | grep -m1 mCurrentFocus | sed 's/^ *//'
}

cmd_status() {
  connect
  echo "TV:      $IP"
  A shell dumpsys power | tr -d '\r' | grep -m1 mWakefulness= | sed 's/^ *mWakefulness=/power:   /'
  echo "focus:   $(cmd_now | sed 's/.*Window{[^ ]* u0 //; s/}$//')"
  echo "muted:   $(is_muted)"
  A shell dumpsys meminfo | tr -d '\r' | grep -E 'Free RAM|Used RAM' | sed 's/^ */ram:     /'
}

cmd_logs() {
  connect
  if [[ -n $1 ]]; then A logcat -d -v time | grep -iE "$1" | tail -200
  else A logcat -d -v time -t 200; fi
}

register status cmd_status "" "power state, foreground app, mute and free RAM"
register now    cmd_now    "" "print the foreground window only"
register logs   cmd_logs   "[regex]" "recent logcat, optionally filtered" \
"Case-insensitive extended regex; shows the last 200 matching lines."
