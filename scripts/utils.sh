#!/usr/bin/bash

read_logging_type_from_env () {
    if ! [ -z "$USE_ZENITY_LOGGING" ]; then
    echo "zenity"
    else
    echo "stdout"
    fi
}
