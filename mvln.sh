#!/usr/bin/env sh

usage() {
    printf 'USAGE: %s SOURCE... DIRECTORY\n' "$(basename "$0")" 1>&2
    printf 'Move SOURCE(s) to DIRECTORY, leaving behind symbolic links.\n' 1>&2
    exit 1
}

die() {
    printf '%s\n' "$(basename "$0"): $1" 1>&2; exit 1
}

depend() {
    for COMMAND in "$@"; do
        type "$COMMAND" > /dev/null 2>&1 || die "FATAL ERROR: Required utility '$COMMAND' is missing."
    done
}

getlast() {
    eval "printf '%s' \${$#}"
}

normalize () {
    realpath -e -s "$1" | sed "s#$(pwd -L)/##"
}

command_gen() {
    cat << %
mv "$1" "$2" && ln -s "$(realpath -e -s "$2")/$(basename "$1")" "$1"
%
}

depend realpath sed

[ $# -ge 2 ] || usage
DESTDIR=$(getlast "$@")
[ -d "$DESTDIR" ] || usage
[ -z "$DEBUG" ] && CMD="eval" || CMD="printf %s\n"

while [ $# -gt 1 ]
do
    [ -e "$1" ] || usage
    $CMD "$(command_gen "$(normalize "$1")" "$DESTDIR")"
    shift
done
