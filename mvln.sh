#!/bin/sh

usage() {
    echo "USAGE: $(basename $0) SOURCE... DIRECTORY"
    echo "Move SOURCE(s) to DIRECTORY, leaving behind symbolic links."
    exit 1
}

if [[ -z $(which realpath) ]]; then
    echo "Your distro is braindead and/or has a slow update pace. Please install realpath."
    exit 1
fi

[[ $# -ge 2 ]] || usage
DIRECTORY="${@: -1}"
[[ -d $DIRECTORY ]] || usage
while [[ $# -gt 1 ]]
do
    [[ -z $DEBUG ]] || echo "mv $1 $DIRECTORY && ln -s $(realpath $DIRECTORY)/$(basename $1) $1"
    [[ -z $DEBUG ]] && mv $1 $DIRECTORY && ln -s $(realpath $DIRECTORY)/$(basename $1) $1
    shift
done
