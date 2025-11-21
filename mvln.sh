#!/usr/bin/env sh

die() {
    echo -e $1; exit 1
}

depend() {
    for COMMAND in $@; do
        which $COMMAND &> /dev/null || die "FATAL ERROR: Required command '$COMMAND' is missing."
    done
}

usage() {
    echo "USAGE: $(basename $0) SOURCE... DIRECTORY"
    echo "Move SOURCE(s) to DIRECTORY, leaving behind symbolic links."
    exit 1
}

normalize () {
    RUNDIR="$(pwd -L)/"
    TARGET=$(realpath -e -s "$1")
    NORMAL=$(echo "$TARGET" | sed "s#${RUNDIR}##g")
    echo "$NORMAL"
}

command_gen() {
    TARGET="$1"
    DESTDIR="$2"
    TEMPLATE=$(cat << %
mv "$TARGET" "$DESTDIR" && ln -s "$(realpath -e -s "$DESTDIR")/$(basename "$TARGET")" "$TARGET"
%
    )
    echo $TEMPLATE
}

depend realpath

[ $# -ge 2 ] || usage
DESTDIR="${@: -1}"
[ -d "$DESTDIR" ] || usage
while [ $# -gt 1 ]
do
    TARGET=$(normalize "$1")
    COMMAND=$(command_gen "$TARGET" "$DESTDIR")
    if [ -z $DEBUG ]; then
            eval "$COMMAND"
        else
            echo "$COMMAND"
    fi
    shift
done
