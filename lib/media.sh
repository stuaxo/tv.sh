# media: playback keys, volume and mute

# prints true/false for the music stream's mute state
is_muted() {
  A shell dumpsys audio | tr -d '\r' |
    awk '/- STREAM_MUSIC:/{f=1} f&&/Muted:/{print $2; exit}'
}

# KEYCODE_VOLUME_MUTE (164) only toggles, so check state first
set_mute() {
  local want=$1 now
  connect
  now=$(is_muted)
  [[ $now == "$want" ]] || A shell input keyevent 164
}

cmd_play()      { send_key 126; }   # KEYCODE_MEDIA_PLAY
cmd_pause()     { send_key 127; }   # KEYCODE_MEDIA_PAUSE
cmd_stop()      { send_key 86; }    # KEYCODE_MEDIA_STOP
cmd_playpause() { send_key 85; }    # KEYCODE_MEDIA_PLAY_PAUSE
cmd_mute()      { set_mute true; }
cmd_unmute()    { set_mute false; }

cmd_vol() {
  case $1 in
    up)   send_key 24 ;;
    down) send_key 25 ;;
    ''|*[!0-9]*) echo "usage: tv vol up|down|<level>" >&2; exit 2 ;;
    *)    connect; A shell media volume --stream 3 --set "$1" ;;
  esac
}

register play      cmd_play      "" "media play"
register pause     cmd_pause     "" "media pause"
register stop      cmd_stop      "" "media stop"
register playpause cmd_playpause "" "toggle play/pause"
register mute      cmd_mute      "" "mute (no-op if already muted)"
register unmute    cmd_unmute    "" "unmute (no-op if not muted)"
register vol       cmd_vol       "up|down|<level>" "change volume" \
"A number sets an absolute level with 'media volume'."
