# apps: launching and managing Android apps

# idle apps that hog RAM; force-stopped by 'tv free'
HOGS=(
  com.netflix.ninja
  com.android.vending
  com.mubi
  com.google.android.youtube.tv
  org.fdroid.fdroid
  com.apple.atve.androidtv.appletv
  com.amazon.amazonvideo.livingroom
  com.amazon.aiv.eu
)

# app aliases -> package (or package/activity); @home = the default launcher
declare -A APPS=(
  [home]=@home
  [iplayer]=org.droidtv.nettvapp4340/com.zeasn.app.linux.MainActivity
  [dailymotion]=org.droidtv.nettvapp1984/com.zeasn.app.linux.MainActivity
  [arte]=org.droidtv.nettvapp1814/com.zeasn.app.linux.MainActivity
  [youtube]=com.google.android.youtube.tv
  [kodi]=org.xbmc.kodi
  [appletv]=com.apple.atve.androidtv.appletv
  [netflix]=com.netflix.ninja
  [mubi]=com.mubi
  [prime]=com.amazon.amazonvideo.livingroom
  [playstore]=com.android.vending
  [fdroid]=org.fdroid.fdroid
)

cmd_free() {
  connect
  for p in "${HOGS[@]}"; do A shell am force-stop "$p"; done
  A shell dumpsys meminfo | grep -E 'Free RAM|Used RAM'
}

cmd_launch() {
  local free=0 quiet=0
  while [[ $1 == --* ]]; do
    case $1 in
      --free)  free=1 ;;
      --quiet) quiet=1 ;;
      *) echo "tv launch: unknown option '$1'" >&2; exit 2 ;;
    esac
    shift
  done
  local app=$1
  [[ -n $app ]] || { echo "tv launch: missing app" >&2; exit 2; }
  local target=${APPS[$app]:-$app}
  connect
  (( free )) && cmd_free
  (( quiet )) && set_mute true
  if [[ $target == @home ]]; then
    A shell input keyevent 3   # KEYCODE_HOME
  elif [[ $target == */* ]]; then
    A shell am start -n "$target"
  else
    # package only: start its launcher activity
    A shell monkey -p "$target" -c android.intent.category.LAUNCHER 1
  fi
}

cmd_foreground() {
  local app=$1
  [[ -n $app ]] || { echo "tv foreground: missing app" >&2; exit 2; }
  local target=${APPS[$app]:-$app}
  connect
  if [[ $target == @home ]]; then
    A shell input keyevent 3   # KEYCODE_HOME
    return
  fi
  if [[ $target != */* ]]; then
    # package only: resolve its launcher activity
    target=$(A shell cmd package resolve-activity --brief \
      -c android.intent.category.LAUNCHER "$target" | tr -d '\r' | tail -1)
    [[ $target == */* ]] || { echo "tv foreground: no launcher activity for $app" >&2; exit 1; }
  fi
  # REORDER_TO_FRONT: reuse the existing instance instead of recreating it
  A shell am start -f 0x20000 -n "$target"
}

cmd_kill() {
  [[ -n $1 ]] || { echo "tv kill: missing app" >&2; exit 2; }
  [[ ${APPS[$1]} == @home ]] && { echo "tv kill: 'home' is not an app" >&2; exit 2; }
  connect
  A shell am force-stop "$(pkg_of "$1")"
}

# never force-stopped by 'tv quit' without --force: launchers, live TV, system UI
PROTECTED=(
  com.spocky.projengmenu
  com.google.android.tvlauncher
  com.google.android.leanbacklauncher
  org.droidtv.zapster
  com.android.systemui
  android
)

cmd_quit() {
  local force=0
  case $1 in
    '') ;;
    --force) force=1 ;;
    *) echo "usage: tv quit [--force]" >&2; exit 2 ;;
  esac
  connect
  local pkg
  pkg=$(A shell dumpsys window | tr -d '\r' | grep -m1 mCurrentFocus |
    sed -n 's/.* u0 \([^/ }]*\).*/\1/p')
  [[ -n $pkg ]] || { echo "tv quit: can't tell what is in the foreground" >&2; exit 1; }
  # the default launcher may not be in PROTECTED
  local home
  home=$(A shell cmd package resolve-activity --brief -a android.intent.action.MAIN \
    -c android.intent.category.HOME | tr -d '\r' | tail -1)
  home=${home%%/*}
  if (( ! force )) && [[ $pkg == "$home" || " ${PROTECTED[*]} " == *" $pkg "* ]]; then
    echo "tv quit: $pkg is the home screen / live TV, not quitting (use --force)" >&2
    exit 1
  fi
  echo "quitting $pkg"
  A shell am force-stop "$pkg"
}

cmd_apps() {
  local all=0
  case $1 in
    '')    ;;
    --all) all=1 ;;
    *) echo "usage: tv apps [--all]" >&2; exit 2 ;;
  esac
  local installed=
  if (( ! all )); then
    adb connect "$IP" >/dev/null 2>&1
    installed=$(A shell pm list packages 2>/dev/null | tr -d '\r' | sed 's/^package://')
    if [[ -z $installed ]]; then
      echo "tv apps: can't reach the TV, showing every alias" >&2
      all=1
    fi
  fi
  local a
  for a in "${!APPS[@]}"; do
    # home is always available; others must be installed on the TV
    if (( all )) || [[ ${APPS[$a]} == @home ]] || grep -qxF "$(pkg_of "$a")" <<<"$installed"; then
      printf '%-12s %s\n' "$a" "${APPS[$a]}"
    fi
  done | sort
}

register launch     cmd_launch     "[--free] [--quiet] <app>" "launch an app" \
"<app> is an alias (see 'tv apps'), a package name, or package/activity.
  'home' goes to the home screen (same as 'tv home').
  --free   run 'tv free' first
  --quiet  mute the TV first"
register foreground cmd_foreground "<app>" "bring an app's existing task to the front" \
"Same app naming as 'launch'. Starts the app if it is not running."
register quit       cmd_quit       "[--force]" "quit the current app" \
"Force-stops whatever app is in the foreground. Refuses on the home screen,
live TV and system UI unless --force is given."
register kill       cmd_kill       "<app>" "force-stop one app"
register free       cmd_free       ""      "force-stop idle RAM-hungry apps"
register apps       cmd_apps       "[--all]" "list app aliases installed on the TV" \
"Queries the TV and hides aliases whose package isn't installed.
  --all  list every alias without contacting the TV"
alias_cmd fg foreground
