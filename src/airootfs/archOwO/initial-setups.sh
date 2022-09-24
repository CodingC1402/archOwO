#!/bin/bash

# Arguments
# - $0 - path to script dir
# - $1 - path to overwrite
# - $2 - append path
overwrite_if_new_file() {
    local -r path="${1}${3}"
    local -r overwrite_path="${2}${3}"

    # If it's a file and newer then the other file
    if [[ -f "$path" && ( ! -f "$overwrite_path" || "$path" -nt "$overwrite_path" ) ]]; then
        echo "Found new file at ${overwrite_path}, overwritting..."
        cp "$path" "$overwrite_path"
        return;
    fi
  
    # If it's a directory
    if [ -d "$path" ]; then
        echo "Loop in folder ${path}"
        mkdir "$overwrite_path"

        # Loop through each to check if it's new
        for idx in "$path"/* ; do
            overwrite_if_new_file "$1" "$2" "${3}/$(basename "$idx")"
        done
        
        return;  
    fi
}

#setup() {
#    # Set up lightdm default bg
#}

main() {
    local -r path=$(readlink -f "$(dirname "$1")")
    local -r testing="false"
    local -r to_overwrite=("etc")

    local overwrite_path=""
    overwrite_path=$(dirname "$path")
    
    if [[ "${testing}" == "true" ]]; then
        echo "Testing..."
        overwrite_path="${overwrite_path}/testing"
        mkdir "$overwrite_path"
    fi

    # Overwrite files
    for dir in "${to_overwrite[@]}" ; do
        local -r basename=$(basename "$dir")

        echo "Checking directory $basename"
        overwrite_if_new_file "$path" "$overwrite_path" "/$basename"
    done

    #setup
}

main "$0"