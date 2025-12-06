#!/usr/bin/env sh

capture() {
  if [ "$1" = "root" ]; then
    shift && set -- -window root "$@"
    else
    shift
  fi
  magick import -silent "$@"
}

unset MODE

while getopts r OPT
do
  case $OPT in
  r)  MODE="root";;
  ?)  printf "no";exit 1;;
  esac
done

shift $((OPTIND - 1))

CAPTURE_DIR="${XDG_PICTURES_DIR:-"$HOME"/Pictures}"
CAPTURE_FMT="png"
CAPTURE_TMP="${CAPTURE_DIR}/screencap_tmp.${CAPTURE_FMT}"

capture "$MODE" "$CAPTURE_TMP"

CAPTURE_TIME="$(date +%F-%H%M%S)"
CAPTURE_DIMS="$(magick identify -format '%wx%h' "$CAPTURE_TMP")"
CAPTURE_SUFX="screencap"
CAPTURE_PATH="${CAPTURE_DIR}/${CAPTURE_TIME}_${CAPTURE_DIMS}_${CAPTURE_SUFX}.${CAPTURE_FMT}"
mv "$CAPTURE_TMP" "$CAPTURE_PATH"
notify-send -a "$0" "Screenshot saved" "$CAPTURE_PATH"
