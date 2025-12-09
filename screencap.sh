#!/usr/bin/env sh
# SPDX-License-Identifier: MIT

usage() {
  cat << EOF 1>&2
usage: $(basename "$0") [-qr] [-d dir] [-f fmt]
Creates and saves a screenshot using ImageMagick.
Left click selects a window, left click and drag selects a region.

Saves into XDG_PICTURES_DIR by default, creating it if it does not exist.
If XDG_PICTURES_DIR is unset, ~/Pictures will be used.

OPTIONS
  -d dir:  Override the default directory. Will be created if needed.
  -f fmt:  Override the default output format. Default is PNG.
  -q:      Suppress notifications.
  -r:      Screenshot the entire root window instead of a selection.
EOF
  die -q "usage error"
}

die() {
  [ ! "$1" = "-q" ] && printf '%s\n' "$(basename "$0"): $1" 1>&2
  [ "$1" = "-q" ] && shift
  [ -z $NONOTIFY ] && notify-send -a "$(basename "$0")" -u critical -i dialog-error "Screencap failed" "$1"
  exit 1
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

# TODO: add check for if the chosen format produces an actual image
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

unset CAPTURE_MODE CAPTURE_DIR CAPTURE_FMT NONOTIFY
type notify-send > /dev/null 2>&1 || NONOTIFY=1
while getopts d:f:qr OPT; do
  case $OPT in
    d)  CAPTURE_DIR="$OPTARG" ;;
    f)  CAPTURE_FMT="$OPTARG" ;;
    q)  NONOTIFY=1 ;;
    r)  CAPTURE_MODE="root" ;;
    ?)  usage ;;
  esac
done
shift $((OPTIND - 1))

depend magick
[ ! "$WAYLAND_DISPLAY" ] && [ ! "$XDG_SESSION_TYPE" = "wayland" ] || die "ImageMagick import does not function on wayland."
xset q > /dev/null 2>&1 || die "Can't find X session."

[ "$CAPTURE_FMT" ] || CAPTURE_FMT="png"
checkfmt "$CAPTURE_FMT" || die "output format '$CAPTURE_FMT' is not supported on your system."

[ "$CAPTURE_DIR" ] || CAPTURE_DIR="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
CAPTURE_TMPDIR="${XDG_CACHE_HOME:-"${HOME}/.cache"}"
checkdir "$CAPTURE_DIR" "$CAPTURE_TMPDIR"

# TODO: make these temp files safer. mktemp isn't part of POSIX so this is non-trivial
CAPTURE_TMP="${CAPTURE_TMPDIR}/screencap_tmp.${CAPTURE_FMT}"
CAPTURE_ICON="${CAPTURE_TMPDIR}/screencap_icon.jpg"
capture "$CAPTURE_MODE" "$CAPTURE_TMP" || die "ABORT: import failed for an unknown reason, most likely on wayland."
# shellcheck disable=SC2064
trap "[ -e '$CAPTURE_TMP' ] && rm -f '$CAPTURE_TMP'" EXIT HUP INT TERM
[ -z $NONOTIFY ] && magick convert "$CAPTURE_TMP" -resize 128x128 "$CAPTURE_ICON"
# shellcheck disable=SC2064
[ -e "$CAPTURE_ICON" ] && trap "rm -f '$CAPTURE_ICON'" EXIT HUP INT TERM

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"

CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"

mv "$CAPTURE_TMP" "$CAPTURE_PATH"
[ -z $NONOTIFY ] && notify-send -a "$(basename "$0")" -i "$CAPTURE_ICON" "Screenshot saved" "$CAPTURE_PATH"

exit 0
