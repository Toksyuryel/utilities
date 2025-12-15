# SPDX-License-Identifier: MIT
#
# Common POSIX-compatible functions used by most scripts

# Set this to any default options you would like passed to err invocations
erropts=""

app="$(basename "$0")"

_notify_err() (
  notify-send -a "$app" -u critical -i dialog-error \
    "$app $1" "$(shift; printf '%s\n' "$@")"
)

_print_err() (
  printf '%s: %s\n' "$app" "$1" 1>&2
  if [ $# -gt 1 ]; then
    shift
    printf '  %s\n' "$@" 1>&2
  fi
)

# err [-qs] [-t str] [msg ...]
# prints a message to stderr and also sends it to the user's notification daemon
# OPTIONS
#   -q      Supress notifications
#   -s      Supress stderr
#   -t str  Set notification title
err() (
  # shellcheck disable=SC2086
  set -- $erropts "$@"
  title="alert"
  unset quiet silent OPTIND
  while getopts qst: OPT; do
    case $OPT in
      q)  quiet=1 ;;
      s)  silent=1 ;;
      t)  title="$OPTARG" ;;
      ?)  ;;
    esac
  done
  shift $((OPTIND - 1))

  [ $# -ge 1 ] || set -- "unknown error"
  [ "$silent" ] \
    || _print_err "$@"
  [ "$quiet" ] \
    || _notify_err "$title" "$@"
)

# die [options] [msg ...]
# Calls err() and exits. For convenience, as this pattern happens a lot.
# See err() for option descriptions
die() {
  err -t "failed" "$@"
  exit 1
}

# depend [name ...]
# reports an error if any name is missing from the user's path
depend() (
  for command in "$@"; do
    if ! type "$command" > /dev/null 2>&1; then
      printf '%s' "Cannot find '$command'; is it in your PATH?"
      return 1
    fi
  done
)

# checkdir_xdg [name ...]
# Checks if the provided names point to directories and are writable
# reports an error message if a provided name points to either:
#   a non-directory file, or a non-writable directory
# If no file matches a provided name, this function will attempt to create it
#   as a directory according to the XDG Base Directories spec
#   or report an error if it cannot
checkdir_xdg() (
  unset msg
  for file in "$@"; do
    if [ -d "$file" ]; then
      [ -x "$file" ] && [ -w "$file" ] \
        || msg="$file exists but is not writable."
    elif [ -e "$file" ]; then
      msg="$file exists but is not a directory."
    else
      # shellcheck disable=SC2174
      mkdir -p -m 0700 "$file" \
        || msg="$file does not exist and could not be created."
    fi
    if [ "$msg" ]; then
      printf '%s' "$msg"
      return 1
    fi
  done
)

# clean [file ...]
# Safely deletes each provided file. Use for cleaning up temporary files.
# Set a trap on EXIT to run this automatically when your script exits
# 
# example usage:
#   trap 'clean "${tmpdir}/*"' EXIT
clean() (
  for file in "$@"; do
    [ -e "$file" ] && unlink "$file"
  done
)
