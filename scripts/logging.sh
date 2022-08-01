#!/usr/bin/bash

if ! [[ $1 != "" && $2 != "" && $3 =~ ^(stdout|zenity)$ ]]; then
    echo "usage: source $0 [mutually exclusive log filename prefix] [title] [stdout|zenity]"
    echo "example: source $0 nixstrap steam-nix-multiuser-log zenity"
else
    log_prefix="/tmp/log-$1"
    log_pipe="$log_prefix-pipe"
    log_log="$log_prefix-log"
    log_mode=$3
    log_title="$2"

    zenity_common_flags="--title=\"$log_title\" --width=400 --height=200"

    show_critical_error() {
        case "$log_mode" in
            "zenity")
                echo "$zenity_common_flags" | xargs zenity --warning --text="$@"
                ;;

            "stdout")
                echo "[$log_title] $@"
                ;;
        esac
    }

    log_init () {
        # we don't really use the pipe in stdout mode... but creating and checking for it has the side benefit of
        # making any process that uses the same log name mutually exclusive

        if [[ ! -p $log_pipe ]]; then
            trap "rm -f $log_pipe $log_log" EXIT
            mkfifo $log_pipe
            exec 3<>$log_pipe
            if [[ "$log_mode" = "zenity" ]]; then
                # todo idk how to use xargs here to insert common flags
                zenity --progress --no-cancel --auto-close --title="$log_title" --width=400 --height=100 <&3 &
                # update exit trap to also get rid of zenity if it's still around (someone forgot to call log_end*)
                trap "rm -f $log_pipe $log_log; kill $! 2>/dev/null" EXIT
            fi
        else 
            show_critical_error "$log_pipe already exists. Is another process running? If there isn't, please remove the file and try again."
            return 1
        fi
    }

    log_message () {
        if [[ ! -p $log_pipe ]]; then
            show_critical_error "log_message was called, but $log_pipe doesn't exist. was log_init called?\nwould have logged:\n$@"
        fi

        # write to log file if we aren't just writing to stdout
        if [[ "$log_mode" != "stdout" ]]; then
            echo "[$(date --iso-8601=seconds)] $@" >> $log_log
        fi

        case "$log_mode" in
            "zenity")
                echo "#$@" >&3
                ;;

            "stdout")
                echo "[$log_title] $@"
                ;;
        esac
    }

    log_init_progress () {
        local is_shellscript_re='shell script'
        if ! [ -z ${log_progress_num_max} ]; then
            show_critical_error "log_init_progress was already called, and log_progress_max was set"
        elif [[ $(file "$0") =~ $is_shellscript_re && "$@" = "" ]]; then
            # automatic progress max - look at the calling shellscript, count how many times it calls log_progress.
            log_progress_num_max="$(cat "$0" | grep log_progress | wc -l)"
            if [ $? -ne 0 ]; then
                show_critical_error "automatically counting log_progress calls in script $0 failed"
            fi
            log_progress_num_current="0"
        elif [[ "$@" =~ [0-9]+ ]]; then
            log_progress_num_max="$@"
            log_progress_num_current="0"
        else
            show_critical_error "log_progress_init was called but without supplying arguments"
        fi
    }

    log_progress () {
        if [ -z ${log_progress_num_max} ] || [ -z ${log_progress_num_current} ]; then
            show_critical_error "log_progress was called before log_progress_init"
        elif [[ "$log_mode" = "zenity" ]]; then
            log_progress_num_current=$((log_progress_num_current+1))
            _log_send_progress_percent_to_ui
        fi
    }
    log_set_progress () {
        if [ -z ${log_progress_num_max} ] || [ -z ${log_progress_num_current} ]; then
            show_critical_error "log_set_progress was called before log_init_progress"
        else
            if [[ "$@" =~ [0-9]+ ]]; then
                log_progress_num_current="$@"
                _log_send_progress_percent_to_ui
            else
                show_critical_error "log_set_progress was called but without supplying numeric arguments"
            fi
        fi
    }

    _log_send_progress_percent_to_ui () {
        local percentage="$(echo "$log_progress_num_current $log_progress_num_max" | awk '{ print ($1 / $2) * 100 }')"
        case "$log_mode" in
            "zenity")
                echo "$percentage" >&3
                ;;

            "stdout")
                ;;
        esac
    }

    log_progress_message () {
        log_progress
        log_message "$@"
    }

    log_end () {
        case "$log_mode" in
            "zenity")
                # send 100 percent to zenity and it'll close.
                echo 100 >&3
                ;;

            "stdout")
                ;;
        esac
        # delete the logs so another process can log
        rm -f $log_pipe $log_log
        unset log_progress_num_max
        unset log_progress_num_current
    }

    log_end_show_all () {
        case "$log_mode" in
            "zenity")
                # send 100 percent to zenity and it'll close.
                echo 100 >&3
                zenity --text-info --filename="$log_log" --title="$log_title" --width=800 --height=500 --cancel-label="OK?" --ok-label="OK!"
                ;;

            "stdout")
                ;;
        esac
        # delete the logs so another process can log
        rm -f $log_pipe $log_log
        unset log_progress_num_max
        unset log_progress_num_current
    }
fi
