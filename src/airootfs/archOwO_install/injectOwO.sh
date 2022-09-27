#!/bin/bash
# The starting file for installaition process

main() {
    echo "Password is OwO"
    sudo /archOwO_install/setup.sh
    read -r _
}

main "$0"