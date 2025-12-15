# SPDX-License-Identifier: MIT
# 
# mkstemps [template] suffix
# a reimplementation of mkstemps(3) for use in POSIX-compatible shell scripts
# needed because mktemp is not in POSIX and m4 only provides mkstemp
mkstemps() (
  unset template suffix
  if [ $# -gt 0 ] && [ $# -lt 3 ]; then
    if [ $# -eq 1 ]; then
      suffix="$1"
    else
      suffix="$2"
      if [ -d "$1" ]; then
        [ -x "$1" ] && [ -w "$1" ] && template="${1}/"
      else
        tmpdir="$(dirname "$1")"
        if printf '%s' "$1" | grep "^[^X]*XXXXXX$" > /dev/null 2>&1 \
          && [ -x "$tmpdir" ] && [ -w "$tmpdir" ]; then
          template="$1"
        fi
      fi
    fi
  fi
  if [ "$suffix" ]; then
    if [ $# -eq 1 ] || [ "$template" ]; then
      while
        tempfile="$(printf 'mkstemp(%s)' "$template" | m4)"
        target="$(printf '%s%s' "$tempfile" "$suffix")"
        link "$tempfile" "$target"; unlink "$tempfile"
        [ ! -e "$target" ]
      do : ; done
      printf '%s' "$target"
    fi
  fi
)
