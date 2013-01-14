#!/bin/bash

usage() {
    echo "USAGE: $(basename $0) SOURCE... DIRECTORY"
    echo "Move SOURCE(s) to DIRECTORY, leaving behind symbolic links."
    exit 1
}

depend_on() {
    for command in $@; do
        which $command &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "This script depends on the '$command' command, please obtain it."
            exit 1
        fi
    done
}

depend_on realpath

[[ $# -ge 2 ]] || usage
DIRECTORY="${@: -1}"
[[ -d $DIRECTORY ]] || usage
while [[ $# -gt 1 ]]
do
    [[ -z $DEBUG ]] || echo "mv $1 $DIRECTORY && ln -s $(realpath $DIRECTORY)/$(basename $1) $1"
    [[ -z $DEBUG ]] && mv $1 $DIRECTORY && ln -s $(realpath $DIRECTORY)/$(basename $1) $1
    shift
done
