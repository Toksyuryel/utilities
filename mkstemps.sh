# SPDX-License-Identifier: MIT
# 
# _mkstemps [template] suffix
# a reimplementation of mkstemps(3) for use in POSIX-compatible shell scripts
# needed because mktemp is not in POSIX and m4 only provides mkstemp
_mkstemps() (
  [ $# -gt 0 ] && [ $# -lt 3 ] || return 1

  if [ $# -eq 1 ]; then
    suffix="$1"
  else
    suffix="$2"
    if [ ! -d "$1" ]; then
      printf '%s' "$1" | grep "^[^X]*XXXXXX$" > /dev/null 2>&1 || return 1
      [ -x "$(dirname "$1")" ] && [ -w "$(dirname "$1")" ] || return 1
      template="$1"
    else
      [ -x "$1" ] && [ -w "$1" ] || return 1
      template="${1}/"
    fi
  fi

  while
    tempfile="$(printf 'mkstemp(%s)' "$template" | m4)"
    target="$(printf '%s%s' "$tempfile" "$suffix")"
    link "$tempfile" "$target"; unlink "$tempfile"
    [ ! -e "$target" ]
  do : ; done
  [ -e "$target" ] || return 2
  printf '%s' "$target"
)
