#!/usr/bin/env sh
# SPDX-License-Identifier: MIT

appdir="$(dirname "$0")"
# shellcheck source-path=SCRIPTDIR
. "${appdir}/common.sh"
. "${appdir}/mkstemps.sh"

usage() {
  cat << EOF 1>&2
usage: $app [-qr] [-d dir] [-f fmt]
Creates and saves a screenshot using ImageMagick.
Left click selects a window, left click and drag selects a region.

OPTIONS
  -d dir:  Output directory. (Default: XDG_PICTURES_DIR or ~/Pictures if unset)
           Missing directories will be created.
  -f fmt:  Output format. (Default: png)
  -q:      Suppress notifications.
  -r:      Select the root window.
EOF
  die -s "usage error"
}

checkfmt() (
  unset msg
  if ! magick identify -list format \
    | grep -iE '^[[:space:]]*'"$1"'(\*)?[[:space:]]+' \
    | awk '{ print $3 }' \
    | grep -q 'w'; then
    msg="format '$1' not supported"
  else
    fmt_tmp="$(mkstemps "$2" ".$1")"
    if [ ! -e "$fmt_tmp" ]; then
      msg="failed to create temp files"
    else
      magick -size 1x1 xc:black "$fmt_tmp"
      magick "$fmt_tmp" "${fmt_tmp}.jpg" > /dev/null 2>&1 \
        || msg="format '$1' not an image"
    fi
  fi
  if [ "$msg" ]; then
    printf '%s' "$msg"
    return 1
  fi
  return 0
)

capture() {
  if [ "$1" = "root" ]; then
    shift && set -- -window root "$@"
  else
    shift
  fi
  magick import -silent "$@"
}

trap 'exit 1' USR1

outdir="${XDG_PICTURES_DIR:-"${HOME}/Pictures"}"
tmpdir="${XDG_CACHE_HOME:-"${HOME}/.cache/$app"}"
format="png"

unset mode OPTIND
# shellcheck disable=SC2015
depend dbus-send notify-send > /dev/null 2>&1 \
  && dbus-send --dest=org.freedesktop.Notifications / \
     org.freedesktop.DBus.Peer.Ping > /dev/null 2>&1 \
  || set -- "-q" "$@"
while getopts d:f:qr opt; do
  case $opt in
    d)  outdir="$OPTARG" ;;
    f)  format="$OPTARG" ;;
    q)  quiet=1; erropts="-q" ;;
    r)  mode="root" ;;
    ?)  usage ;;
  esac
done
shift $((OPTIND - 1))

error="$(depend magick)"
[ ! "$error" ] || die "$error"

[ ! "$WAYLAND_DISPLAY" ] && [ ! "$XDG_SESSION_TYPE" = "wayland" ] \
  || die "ImageMagick import does not function on wayland."
xset q > /dev/null 2>&1 || die "Can't find X session."

error="$(checkdir_xdg "$outdir" "$tmpdir")"
[ ! "$error" ] || die "$error"

trap 'clean "${tmpdir}/"*' EXIT

template="${tmpdir}/${app}XXXXXX"
tmpname="$(mkstemps "$template" ".$format")"
[ -e "$tmpname" ] || die "failed to create temp files"
if [ ! "$quiet" ]; then
  icon="$(mkstemps "$template" ".jpg")"
  [ -e "$icon" ] || die "failed to create temp files"
fi

error="$(checkfmt "$format" "$template")"
[ ! "$error" ] || die "$error"

capture "$mode" "$tmpname" \
  || die "import failed for an unknown reason, most likely on wayland."
[ ! "$quiet" ] \
  && magick "$tmpname" -resize 128x128 "$icon"

time="$(date +%F-%H%M%S)"
dims="$(magick identify -format '%wx%h' "$tmpname")"
suffix="screencap"

outname="${outdir}/${time}_${dims}_${suffix}.${format}"

link "$tmpname" "$outname" || die "rename failed"
chmod "$(printf '%.4o' $((0666 & (~$(umask)))))" "$outname" \
  || err "failed to set file permissions"
[ ! "$quiet" ] \
  && notify-send -a "$app" -i "$icon" "Screenshot saved" "$outname"

exit 0
