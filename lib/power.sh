# power: sleep, wake, reboot, shutdown

cmd_sleep() { send_key 223; }   # KEYCODE_SLEEP
cmd_wake()  { send_key 224; }   # KEYCODE_WAKEUP
cmd_reboot()   { connect; A reboot; }
cmd_shutdown() { connect; A shell reboot -p; }

register sleep    cmd_sleep    "" "send the TV to standby"
register wake     cmd_wake     "" "wake from standby"
register reboot   cmd_reboot   "" "reboot the TV"
register shutdown cmd_shutdown "" "power off completely (not standby)"
