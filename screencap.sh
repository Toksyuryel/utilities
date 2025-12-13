#!/usr/bin/env sh
# SPDX-License-Identifier: MIT

# shellcheck source-path=SCRIPTDIR
. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/mkstemps.sh"

usage() {
  cat << EOF 1>&2
usage: $(basename "$0") [-qr] [-d dir] [-f fmt]
Creates and saves a screenshot using ImageMagick.
Left click selects a window, left click and drag selects a region.

OPTIONS
  -d dir:  Output directory. (Default: XDG_PICTURES_DIR or ~/Pictures if unset)
           Missing directories will be created.
  -f fmt:  Output format. (Default: png)
  -q:      Suppress notifications.
  -r:      Select the root window.
EOF
  _err -fs "usage error"
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

trap 'exit 1' USR1

CAPTURE_DIR="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
CAPTURE_TMPDIR="${XDG_CACHE_HOME:-"${HOME}/.cache/$(basename "$0")"}"
CAPTURE_FMT="png"

unset CAPTURE_MODE OPTIND
type notify-send > /dev/null 2>&1 || _erropts="-q"
while getopts d:f:qr OPT; do
  case $OPT in
    d)  CAPTURE_DIR="$OPTARG" ;;
    f)  CAPTURE_FMT="$OPTARG" ;;
    q)  _erropts="-q" ;;
    r)  CAPTURE_MODE="root" ;;
    ?)  usage ;;
  esac
done
shift $((OPTIND - 1))

depend magick
[ ! "$WAYLAND_DISPLAY" ] && [ ! "$XDG_SESSION_TYPE" = "wayland" ] \
  || _err -f "ImageMagick import does not function on wayland."
xset q > /dev/null 2>&1 || _err -f "Can't find X session."

checkfmt "$CAPTURE_FMT" \
  || _err -f "output format '$CAPTURE_FMT' is not supported on your system."
checkdir_xdg "$CAPTURE_DIR" "$CAPTURE_TMPDIR"
trap '_clean "$CAPTURE_TMPDIR/"*' EXIT

CAPTURE_TMP="$(_mkstemps "${CAPTURE_TMPDIR}/$(basename "$0")XXXXXX" ".${CAPTURE_FMT}")" \
  || _err -f "failed to create temp files"
if [ -z "$_erropts" ]; then
  CAPTURE_ICON="$(_mkstemps "${CAPTURE_TMPDIR}/$(basename "$0")XXXXXX" ".jpg")" \
    || _err -f "failed to create temp files"
fi

capture "$CAPTURE_MODE" "$CAPTURE_TMP" \
  || _err -f "import failed for an unknown reason, most likely on wayland."
[ -z "$_erropts" ] \
  && magick "$CAPTURE_TMP" -resize 128x128 "$CAPTURE_ICON"

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"

CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"

link "$CAPTURE_TMP" "$CAPTURE_PATH" || _err -f "rename failed"
chmod "$(printf '%.4o' $((0666 & (~$(umask)))))" "$CAPTURE_PATH" \
  || _err "ALERT: failed to set file permissions"
[ -z "$_erropts" ] \
  && notify-send -a "$(basename "$0")" -i "$CAPTURE_ICON" "Screenshot saved" "$CAPTURE_PATH"

exit 0
