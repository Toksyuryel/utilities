# SPDX-License-Identifier: MIT
# 
# _mkstemps [template] suffix
# a reimplementation of mkstemps(3) for use in POSIX-compatible shell scripts
# needed because mktemp is not in POSIX and m4 only provides mkstemp
_mkstemps() {
  [ $# -gt 0 ] && [ $# -lt 3 ] || return 1

  if [ $# -eq 1 ]; then
    __suffix="$1"
  else
    __suffix="$2"
  fi

  if [ $# -eq 2 ]; then
    if [ ! -d "$1" ]; then
      printf '%s' "$1" | grep "^[^X]*XXXXXX$" || return 1
      [ -x "$(dirname "$1")" ] && [ -w "$(dirname "$1")" ] || return 1
      __template="$1"
    else
      [ -x "$1" ] && [ -w "$1" ] || return 1
      __template="${1}/"
    fi
  fi

  while
    __tempfile="$(printf 'mkstemp(%s)' "$__template" | m4)"
    __target="$(printf '%s%s' "$__tempfile" "$__suffix")"
    link "$__tempfile" "$__target"; unlink "$__tempfile"
    [ ! -e "$__target" ]
  do : ; done
  [ -e "$__target" ] || return 2
  printf '%s' "$__target"
}
