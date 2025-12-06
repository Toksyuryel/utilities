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
CAPTURE_PATH="${CAPTURE_DIR}/screencap_tmp.png"

capture "$MODE" "$CAPTURE_PATH"
mv "$CAPTURE_PATH" "${CAPTURE_DIR}/$(date +%F-%H%M%S)_$(magick identify -format '%wx%h' "$CAPTURE_PATH")_screencap.png"
