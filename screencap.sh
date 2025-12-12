#!/usr/bin/env sh
# SPDX-License-Identifier: MIT

# shellcheck source-path=SCRIPTDIR
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
  err -fs $QUIET "usage error"
}

err() (
  sev="alert"
  unset quiet silent
  while getopts fqs OPT; do
    case $OPT in
      f)  sev="failed" ;;  # fatal: cannot continue, abort execution
      q)  quiet=1 ;;       # suppress notifications
      s)  silent=1 ;;      # suppress stderr
      ?)  ;;
    esac
  done
  shift $((OPTIND - 1))

  msg="${1:-Unknown error}"
  app="$(basename "$0")"

  [ -z $silent ] && printf '%s:%s\n' "$app" "$msg" 1>&2
  [ -z $quiet ] && notify-send -a "$app" -u critical -i dialog-error "$app $sev" "$msg"
  [ "$sev" = "failed" ] && kill -ABRT -- -$$
  return 0
)

# shellcheck disable=SC2329
_abort() {
  exit 1
}
trap '_abort' ABRT

depend() (
  for command in "$@"; do
    type "$command" > /dev/null 2>&1 || err -f $QUIET "FATAL ERROR: Required utility '$command' is missing."
  done
)

checkdir() (
  for file in "$@"; do
    if [ -e "$file" ]; then
      [ -d "$file" ] || err -f $QUIET "$file exists but is not a directory."
      [ -x "$file" ] && [ -w "$file" ] || err -f $QUIET "$file exists but is not writable."
    else
      # shellcheck disable=SC2174
      mkdir -p -m 0700 "$file" || err -f $QUIET "$file doesn't exist and could not be created."
    fi
  done
)

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

# shellcheck disable=SC2329
_clean() (
  for file in "$@"; do
    [ -e "$file" ] && unlink "$file"
  done
)

CAPTURE_DIR="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
CAPTURE_TMPDIR="${XDG_CACHE_HOME:-"${HOME}/.cache/$(basename "$0")"}"
CAPTURE_FMT="png"

unset CAPTURE_MODE QUIET
type notify-send > /dev/null 2>&1 || QUIET="-q"
while getopts d:f:qr OPT; do
  case $OPT in
    d)  CAPTURE_DIR="$OPTARG" ;;
    f)  CAPTURE_FMT="$OPTARG" ;;
    q)  QUIET="-q" ;;
    r)  CAPTURE_MODE="root" ;;
    ?)  usage ;;
  esac
done
shift $((OPTIND - 1))

depend magick
[ ! "$WAYLAND_DISPLAY" ] && [ ! "$XDG_SESSION_TYPE" = "wayland" ] || err -f $QUIET "ImageMagick import does not function on wayland."
xset q > /dev/null 2>&1 || err -f $QUIET "Can't find X session."

checkfmt "$CAPTURE_FMT" || err -f $QUIET "output format '$CAPTURE_FMT' is not supported on your system."
checkdir "$CAPTURE_DIR" "$CAPTURE_TMPDIR"
trap '_clean "$CAPTURE_TMPDIR/"*' EXIT

CAPTURE_TMP="$(_mkstemps "${CAPTURE_TMPDIR}/$(basename "$0")XXXXXX" ".${CAPTURE_FMT}")" || err -f $QUIET "failed to create temp files"
if [ -z $QUIET ]; then
  CAPTURE_ICON="$(_mkstemps "${CAPTURE_TMPDIR}/$(basename "$0")XXXXXX" ".jpg")" || err -f $QUIET "failed to create temp files"
fi

capture "$CAPTURE_MODE" "$CAPTURE_TMP" || err -f $QUIET "import failed for an unknown reason, most likely on wayland."
[ -z $QUIET ] && magick "$CAPTURE_TMP" -resize 128x128 "$CAPTURE_ICON"

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"

CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"

link "$CAPTURE_TMP" "$CAPTURE_PATH" || err -f $QUIET "rename failed"
chmod "$(printf '%.4o' $((0666 & (~$(umask)))))" "$CAPTURE_PATH" || err $QUIET "ALERT: failed to set file permissions"
[ -z $QUIET ] && notify-send -a "$(basename "$0")" -i "$CAPTURE_ICON" "Screenshot saved" "$CAPTURE_PATH"

exit 0
