#!/bin/bash

main() {
    # start/restart pulseaudio
    local -r isRunning=$(pulseaudio --check)
    if (( isRunning != 0 )); then
        pulseaudio -D
    fi
}

main "$0"