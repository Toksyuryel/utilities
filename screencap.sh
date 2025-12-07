#!/usr/bin/env sh

usage() {
  printf 'USAGE: %s [-r]\n' "$(basename "$0")" 1>&2
  printf 'Creates and saves a screenshot.\n' 1>&2
  printf 'Left click selects a window, left click and drag selects a region.\n'
  printf '\n'
  printf 'OPTIONS:\n' 1>&2
  printf '\t-r\t Screenshot the entire root window instead of making a selection.\n' 1>&2
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

checkdir() {
  for DIR in "$@"; do
    if [ -e "$DIR" ]; then
      [ -d "$DIR" ] || die "$DIR exists but is not a directory."
      [ -x "$DIR" ] && [ -w "$DIR" ] || die "$DIR exists but is not writable."
      else
      # shellcheck disable=SC2174
      mkdir -p -m 0700 "$DIR" || die "$DIR doesn't exist and could not be created."
    fi
  done
}

capture() {
  if [ "$1" = "root" ]; then
    shift && set -- -window root "$@"
    else
    shift
  fi
  magick import -silent "$@"
}

depend magick
xset q > /dev/null 2>&1 || die "Can't find X session."

unset MODE

while getopts r OPT
do
  case $OPT in
  r)  MODE="root";;
  ?)  usage;;
  esac
done

shift $((OPTIND - 1))

CAPTURE_FMT="png"
CAPTURE_DIR="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
CAPTURE_TMPDIR="${XDG_CACHE_HOME:-"${HOME}/.cache"}"
checkdir "$CAPTURE_DIR" "$CAPTURE_TMPDIR"
CAPTURE_TMP="${CAPTURE_TMPDIR}/screencap_tmp.${CAPTURE_FMT}"

capture "$MODE" "$CAPTURE_TMP"

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"
CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"
mv "$CAPTURE_TMP" "$CAPTURE_PATH"
notify-send -a "$0" "Screenshot saved" "$CAPTURE_PATH"
