#!/usr/bin/env sh

usage() {
  printf 'USAGE: %s [-r] [-d dir] [-f fmt]\n' "$(basename "$0")" 1>&2
  printf 'Creates and saves a screenshot using ImageMagick.\n' 1>&2
  printf 'Left click selects a window, left click and drag selects a region.\n' 1>&2
  printf '\n' 1>&2
  printf 'Saves into XDG_PICTURES_DIR by default, creating it if it does not exist.\n' 1>&2
  printf 'If XDG_PICTURES_DIR is unset, ~/Pictures will be used.\n' 1>&2
  printf '\n' 1>&2
  printf 'OPTIONS:\n' 1>&2
  printf '\t-d dir\t Override the default directory. Will be created if needed.\n' 1>&2
  printf '\t-f fmt\t Override the default output format. Default is PNG.\n' 1>&2
  printf '\t-r\t Screenshot the entire root window instead of a selection.\n' 1>&2
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

checkfmt() {
  magick identify -list format \
    | grep -iE '^[[:space:]]*'"$1"'(\*)?[[:space:]]+' \
    | awk '{ print $3 }' \
    | grep -q 'w'
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
[ ! "$WAYLAND_DISPLAY" ] && [ ! "$XDG_SESSION_TYPE" = "wayland" ] || die "ImageMagick import does not function on wayland."
xset q > /dev/null 2>&1 || die "Can't find X session."

unset MODE CAPTURE_DIR CAPTURE_FMT

while getopts d:f:r OPT; do
  case $OPT in
    d)  CAPTURE_DIR="$OPTARG" ;;
    f)  CAPTURE_FMT="$OPTARG" ;;
    r)  CAPTURE_MODE="root" ;;
    ?)  usage ;;
  esac
done

shift $((OPTIND - 1))

[ "$CAPTURE_FMT" ] || CAPTURE_FMT="png"
checkfmt "$CAPTURE_FMT" || die "output format '$CAPTURE_FMT' is not supported on your system."

[ "$CAPTURE_DIR" ] || CAPTURE_DIR="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
CAPTURE_TMPDIR="${XDG_CACHE_HOME:-"${HOME}/.cache"}"
checkdir "$CAPTURE_DIR" "$CAPTURE_TMPDIR"

CAPTURE_TMP="${CAPTURE_TMPDIR}/screencap_tmp.${CAPTURE_FMT}"
capture "$CAPTURE_MODE" "$CAPTURE_TMP"

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"

CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"
mv "$CAPTURE_TMP" "$CAPTURE_PATH"
type notify-send > /dev/null 2>&1 && notify-send -a "$0" "Screenshot saved" "$CAPTURE_PATH"
