#!/usr/bin/env sh

die() {
    printf "%s\n" "$(basename "$0"): $1" 1>&2; exit 1
}

depend() {
    for COMMAND in "$@"; do
        type "$COMMAND" > /dev/null 2>&1 || die "FATAL ERROR: Required command '$COMMAND' is missing."
    done
}

usage() {
    printf "USAGE: %s SOURCE... DIRECTORY\n" "$(basename "$0")" 1>&2
    printf "Move SOURCE(s) to DIRECTORY, leaving behind symbolic links.\n" 1>&2
    exit 1
}

getlast() {
    eval "printf '%s' \"\${$#}\""
}

normalize () {
    realpath -e -s "$1" | sed "s#$(pwd -L)/##"
}

command_gen() {
    cat << %
mv "$1" "$2" && ln -s "$(realpath -e -s "$2")/$(basename "$1")" "$1"
%
}

depend realpath

[ $# -ge 2 ] || usage
DESTDIR=$(getlast "$@")
[ -d "$DESTDIR" ] || usage

while [ $# -gt 1 ]
do
    [ -e "$1" ] || usage
    COMMAND=$(command_gen "$(normalize "$1")" "$DESTDIR")
    if [ -z "$DEBUG" ]; then
            eval "$COMMAND"
        else
            printf "%s\n" "$COMMAND"
    fi
    shift
done
