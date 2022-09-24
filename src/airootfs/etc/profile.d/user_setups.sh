#!/bin/bash

# This file is to make sure that user specific settings are correct.
# For system wide changes go to initial setup script

main() {
    local -r darkThemes=("Adwaita-dark" "dark")

    # start/restart pulseaudio
    #local -r isRunning=$(pulseaudio --check)
    #if (( isRunning != 0 )); then
    #    pulseaudio -D
    #fi

    # change gnome theme according to xfce theme
    local -r currentXfceTheme=$(xfconf-query -c xsettings -p /Net/ThemeName)
    local gnomeTheme="prefer-light"
    for theme in "${darkThemes[@]}" ; do
        if [[ "$theme" == "$currentXfceTheme" ]] ; then
            gnomeTheme="prefer-dark"
        fi
    done

    gsettings set org.gnome.desktop.interface color-scheme "$gnomeTheme"
}

main "$0"