# tools: housekeeping and the CLI itself

cmd_wait() {
  local limit=${1:-180} i
  for (( i=0; i<limit; i+=3 )); do
    if adb connect "$IP" >/dev/null 2>&1 &&
       [[ $(A shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') == 1 ]]; then
      echo "TV is up"; return 0
    fi
    sleep 3
  done
  echo "tv wait: timed out after ${limit}s" >&2; return 1
}

cmd_debloat() {
  exec "${TV_DEBLOAT:-tv-debloat.sh}" "$@"
}

cmd_commands() {
  printf '%s\n' "${!CMD_FN[@]}" "${!CMD_ALIAS[@]}" | sort
}

cmd_completion() {
  cat <<'COMP'
# source this from ~/.bashrc, or ~/.zshrc after: autoload -U +X bashcompinit && bashcompinit
_tv() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmds apps
  cmds=$(tv commands 2>/dev/null)
  apps=$(tv apps --all 2>/dev/null | awk '{print $1}')
  case $prev in
    launch|foreground|fg|kill|--free|--quiet) COMPREPLY=($(compgen -W "$apps --free --quiet" -- "$cur")) ;;
    input) COMPREPLY=($(compgen -W "$(tv inputs --all 2>/dev/null | awk '{print $1}')" -- "$cur")) ;;
    vol|channel|ch) COMPREPLY=($(compgen -W "up down" -- "$cur")) ;;
    help) COMPREPLY=($(compgen -W "$cmds" -- "$cur")) ;;
    *) COMPREPLY=($(compgen -W "$cmds" -- "$cur")) ;;
  esac
}
complete -F _tv tv
COMP
}

register wait       cmd_wait       "[secs]" "wait until the TV is reachable and booted" \
"Default timeout 180s. Useful as: tv reboot && tv wait && tv launch iplayer"
register debloat    cmd_debloat    "<args>" "run tv-debloat.sh" \
"Runs tv-debloat.sh from PATH; TV_DEBLOAT overrides the script path."
register commands   cmd_commands   ""       "list all command names and aliases"
register completion cmd_completion ""       "print a bash/zsh completion script"
register help       cmd_help       "[command]" "show this help, or help for one command"
