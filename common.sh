# SPDX-License-Identifier: MIT
#
# Common POSIX-compatible functions used by most scripts

# Set this to any default options you would like passed to _err invocations
_erropts=""

# in dash $$ does not match the pgid, but can still be used to obtain the pgid
pgid="$(ps -o pgid= $$ | sed 's/[[:space:]]//g')"

# _err [-fqs] [msg]
# prints a message to stderr and also sends it to the user's notification daemon
# OPTIONS
#   -f  Also send SIGUSR1 to the caller's process group. Use for fatal errors.
#   -q  Supress notifications
#   -s  Supress stderr
#
# trap the USR1 signal in your script if you want to set the exit status
_err() (
  trap 'exit 1' USR1  # this prevents the shell from dumping tokens
  sev="alert"
  # shellcheck disable=SC2086
  set -- $_erropts "$@"
  unset quiet silent OPTIND
  while getopts fqs OPT; do
    case $OPT in
      f)  sev="failed" ;;
      q)  quiet=1 ;;
      s)  silent=1 ;;
      ?)  ;;
    esac
  done
  shift $((OPTIND - 1))  

  msg="${1:-Unknown error}"
  app="$(basename "$0")"

  [ "$silent" = "1" ] \
    || printf '%s: %s\n' "$app" "$msg" 1>&2
  [ "$quiet" = "1" ] \
    || notify-send -a "$app" -u critical -i dialog-error "$app $sev" "$msg"
  if [ "$sev" = "failed" ]; then
    kill -s USR1 -- "-$pgid"
    sleep 5s # this is hopefully long enough for a response
    return 1 # communicate the failure and pray
  else
    return 0
  fi
)

# depend [name ...]
# Aborts execution and reports an error messsage if
#  any of the provided names are missing from the user's path
depend() (
  for command in "$@"; do
    type "$command" > /dev/null 2>&1 \
      || _err -f "Cannot find '$command'; is it in your PATH?"
  done
)

# checkdir_xdg [name ...]
# Checks if the provided names point to directories and are writable
# Aborts execution and reports an error message if a provided name
#  points to either a non-directory file, or a non-writable directory
# If no file matches a provided name, this function will attempt to create it
#  as a directory according to the XDG Base Directories spec
checkdir_xdg() (
  for file in "$@"; do
    if [ -e "$file" ]; then
      [ -d "$file" ] \
        || _err -f "$file exists but is not a directory."
      [ -x "$file" ] && [ -w "$file" ] \
        || _err -f "$file exists but is not writable."
    else
      # shellcheck disable=SC2174
      mkdir -p -m 0700 "$file" \
        || _err -f "$file does not exist and could not be created."
    fi
  done
)

# _clean [file ...]
# Safely deletes each provided file. Use for cleaning up temporary files.
# Set a trap on EXIT to run this automatically when your script exits
# 
# example usage:
#   trap '_clean "${tmpdir}/*"' EXIT
_clean() (
  for file in "$@"; do
    [ -e "$file" ] && unlink "$file"
  done
)
