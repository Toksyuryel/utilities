#!/usr/bin/env sh

# set -x

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
    shift $(($#-1))
    printf '%s' "$1"
}

getfullpath() {
    printf '%s' "$(cd "$(dirname "$1")" && pwd -L)/$(basename "$1")" | sed 's#/\.$##'
}

normalize () {
    getfullpath "$1" | sed "s#^$(printf '%s' "$(pwd -L)" | awk '{gsub(/[{[^$*?+.|\\]/, "\\\\&", $0);printf "%s", $0}')/##"
}

command_gen() {
    cat << %
mv "$1" "$2" && ln -s "$3" "$1"
%
}

depend sed awk

unset OPTV

while getopts v OPT
do
    case $OPT in
    v) OPTV=1;;
    ?) usage;;
    esac
done

shift $((OPTIND - 1))

[ $# -ge 2 ] || usage
DST="$(getlast "$@")"
[ -d "$DST" ] || usage
[ -z "$DEBUG" ] && CMD="eval" || CMD="printf %s\n"

while [ $# -gt 1 ]
do
    [ -e "$1" ] || usage
    TGT="$(getfullpath "$DST")/$(basename "$1")"
    $CMD "$(command_gen "$(normalize "$1")" "$DST" "$TGT")"
    if [ -z "$DEBUG" ] && [ ! -z "$OPTV" ]; then
        printf '%s\n' "mv: renamed '$1' -> '$(printf '%s' "$(dirname "$DST")/" | sed 's#^\./##')$(basename "$DST")/$(basename "$1")'"
        printf '%s\n' "ln: '$1' -> '$TGT'"
    fi
    shift
done
