# tv.sh

A small bash script to control a Philips Android TV over ADB.

I now use [tveee](https://github.com/stuaxo/tveee), a Rust port, myself, but
this version has the advantage that the code is easy to read and tweak.

Needs `adb` (and `scrcpy` for `tv mirror`). Put `tv` on your PATH (a symlink
is fine); commands live in `lib/<category>.sh`. Set `TV_IP` to your TV's address.

```
$ tv
Usage: tv <command> [args]

Type 'tv help <command>' for help on a specific command.

[apps]
    apps         list app aliases installed on the TV
    foreground   bring an app's existing task to the front (alias: fg)
    free         force-stop idle RAM-hungry apps
    kill         force-stop one app
    launch       launch an app
    quit         quit the current app

[display]
    mirror       show/control the screen on this PC with scrcpy (alias: scrcpy)
    screenshot   save a PNG of the screen

[info]
    logs         recent logcat, optionally filtered
    now          print the foreground window only
    status       power state, foreground app, mute and free RAM

[input]
    back         press the back button
    channel      change TV channel (alias: ch)
    home         go to the home screen
    input        switch input source
    inputs       list the TV's input sources
    key          send any remote key
    text         type text into the focused field

[media]
    mute         mute (no-op if already muted)
    pause        media pause
    play         media play
    playpause    toggle play/pause
    stop         media stop
    unmute       unmute (no-op if not muted)
    vol          change volume

[power]
    reboot       reboot the TV
    shutdown     power off completely (not standby)
    sleep        send the TV to standby
    wake         wake from standby

[tools]
    commands     list all command names and aliases
    completion   print a bash/zsh completion script
    debloat      run tv-debloat.sh
    help         show this help, or help for one command
    wait         wait until the TV is reachable and booted

Env: TV_IP (default 192.168.1.19), TV_LIB (default lib/ next to the tv script)
```
