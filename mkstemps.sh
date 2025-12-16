# SPDX-License-Identifier: MIT
# 
# mkstemps [template] suffix
# a reimplementation of mkstemps(3) for use in POSIX-compatible shell scripts
# needed because mktemp is not in POSIX and m4 only provides mkstemp
mkstemps() (
  unset template
  if [ $# -eq 1 ]; then
    suffix="$1"
  elif [ $# -eq 2 ]; then
    suffix="$2"
    if [ ! -d "$1" ]; then
      printf '%s' "$1" | grep "^[^X]*XXXXXX$" > /dev/null 2>&1 || return 1
      tmpdir="$(dirname "$1")"
      template="$1"
    else
      tmpdir="$1"
      template="${1}/"
    fi
    [ -x "$tmpdir" ] && [ -w "$tmpdir" ] || return 1
  else
    return 1
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
