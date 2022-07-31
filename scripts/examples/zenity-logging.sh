#!/usr/bin/bash
SCRIPTDIR=$(dirname $(realpath -- "$0";))

source "$SCRIPTDIR/../utils.sh" zenity-logging-sample "Zenity logging sample" zenity
log_init
log_init_progress

echo "found $log_progress_num_max lines containing log_progress, progress bar will complete after log_progress is called that many times"

log_progress_message "hi there! i'm the zenity logging sample."
sleep 1
log_progress_message "i'll take about..."
sleep 1
log_progress_message "maybe... ten-ish seconds to complete?"
sleep 1
log_progress_message "this will demonstrate"
sleep 1
log_progress_message "progress bar and message printing."
sleep 1
log_message "I can also update the message without incrementing progress..."
sleep 1
log_progress_message "and increment progress without printing a message (watch for it!)"
sleep 1
log_progress_message "(here it comes!)"
sleep 1
log_progress
sleep 1
log_progress_message "ok, bye!"
sleep 1
log_progress

log_end_show_all # or log_end if you don't need to show the user the whole log (i.e. if there were no problems)
