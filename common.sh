# SPDX-License-Identifier: MIT
#
# Common POSIX-compatible functions used by most scripts

# set this to "-q" when you want calls to err from these functions to pass it
# setting this to anything else will probably breaks something, so don't do that
unset QUIET

# err [-fqs] [msg]
# prints a message to stderr and also sends it to the user's notification daemon
# OPTIONS
#   -f  Also send SIGABRT to the caller's process group. Use for fatal errors.
#   -q  Supress notifications
#   -s  Supress stderr
err() (
  sev="alert"
  unset quiet silent
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

  [ -z $silent ] \
    && printf '%s:%s\n' "$app" "$msg" 1>&2
  [ -z $quiet ] \
    && notify-send -a "$app" -u critical -i dialog-error "$app $sev" "$msg"
  [ "$sev" = "failed" ] && kill -ABRT -- -$$
  return 0
)

# This exists only to catch SIGABRT and set a more useful exit status
# Please never call this manually
# shellcheck disable=SC2329
_abort() {
  exit 1
}
# Add the following line to your script if you want to use this function
# trap '_abort' ABRT

# depend [name ...]
# Aborts execution and reports an error messsage if
#  any of the provided names are missing from the user's path
depend() (
  for command in "$@"; do
    type "$command" > /dev/null 2>&1 \
      || err -f $QUIET "Can't find '$command'; is it in your PATH?"
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
        || err -f $QUIET "$file exists but is not a directory."
      [ -x "$file" ] && [ -w "$file" ] \
        || err -f $QUIET "$file exists but is not writable."
    else
      # shellcheck disable=SC2174
      mkdir -p -m 0700 "$file" \
        || err -f $QUIET "$file doesn't exist and could not be created."
    fi
  done
)

# _clean [file ...]
# Safely deletes each provided file. Use for cleaning up temporary files.
# Set a trap on EXIT to run this automatically when your script exits
_clean() (
  for file in "$@"; do
    [ -e "$file" ] && unlink "$file"
  done
)
# example usage:
# trap '_clean "${tmpdir}/*"' EXIT
