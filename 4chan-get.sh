#!/bin/bash

# stop on unhandled error
set -e

usage () {
    echo "Usage: $(basename "$0") [OPTION] [URL]..."
    echo "Download images from 4chan threads to subdirectories"
    echo "of the current directory (named based on thread)."
    echo
    echo "Options"
    echo "  -n, --no-fetch  just dump image urls, don't fetch"
    echo "  -N, --fetch     reverse an earlier --no-fetch"
    echo "  -f, --flat      don't use subdirectories"
    echo "  -F, --no-flat   reverse an earlier --flat"
    echo "  -h, --help      show this help message"
}

log_msg () {
    echo "$(date --iso-8601=seconds)	$@" 1>&2
}

extract_urls () {
    for url in $@ ; do
        link_scheme="$(echo "$url" | cut -d '/' -f1)"
        link_board="$(echo "$url" | cut -d '/' -f4)"
        link_thread="$(echo "$url" | cut -d '/' -f6)"
        response="$(curl -s "$link_scheme//a.4cdn.org/$link_board/thread/${link_thread}.json")"
        if [ -z "$response" ] ; then
            log_msg "$url seems to have 404'd, or your connection's janky."
            continue
        fi
        thread_name="$(echo "${response}" | jq -r '.posts[].semantic_url | select(. != null)' | head -n1)"
        if [ -z "$thread_name" ] ; then
            thread_name="${link_board}_${link_thread}"
        else
            thread_name="${thread_name}_${link_board}_${link_thread}"
        fi
        echo "${response}" \
            | jq -r '.posts[] | select(.ext != null) | (.tim | tostring) + .ext + ";" + (.tim | tostring) + "_" + .filename + .ext' \
            | sed 's_^_'"$link_scheme"'//i.4cdn.org/'"$link_board"'/_' \
            | sed 's|$|;'"$thread_name"'|'
    done
}

fetch_url () {
    in_url="$1"
    out_fname="$2"
    out_dir="$3"
    n="$4"

    out_fpath="$out_dir/$out_fname"

    mkdir -p "$out_dir"

    if [ -f "$out_fpath" ] ; then
        log_msg "Already got image #$n as '$out_fpath'"
    else
        curl -s "$in_url" > "$out_fpath"
        if [ -f "$out_fpath" ] ; then
            log_msg "Downloaded image #$n as '$out_fpath'"
        else
            log_msg "Download failed for image #$n :("
        fi
    fi
}

print_urls() {
    while read url_fname_dir; do
        [ -n "$url_fname_dir" ] || continue
        url="$(echo "${url_fname_dir}" | cut -d ';' -f1)"
        fname="$(echo "${url_fname_dir}" | cut -d ';' -f2)"
        echo "${url}"
    done
}

fetch_urls() {
    use_dirs="$1"
    counter=1
    while read url_fname_dir; do
        [ -n "$url_fname_dir" ] || continue
        url="$(echo "${url_fname_dir}" | cut -d ';' -f1)"
        fname="$(echo "${url_fname_dir}" | cut -d ';' -f2)"
        if [ "$use_dirs" = "yes" ] ; then
            out_dir="$(echo "${url_fname_dir}" | cut -d ';' -f3)"
        else
            out_dir="."
        fi
        fetch_url "${url}" "${fname}" "${out_dir}" "${counter}"
        counter=$(( counter + 1 ))
    done
}


declare -a in_urls
show_usage=no
do_fetch=yes
use_dirs=yes

if [ -z "$1" ] ; then
    show_usage=yes
fi

while [ -n "$1" ] ; do
    case "$1" in
        '-h') ;&
        '--help')
            show_usage=yes
            shift
            ;;
        '-n') ;&
        '--no-fetch')
            do_fetch=no
            shift
            ;;
        '-N') ;&
        '--fetch')
            do_fetch=yes
            shift
            ;;
        '-f') ;&
        '--flat')
            use_dirs=no
            shift
            ;;
        '-F') ;&
        '--no-flat')
            use_dirs=yes
            shift
            ;;
        *)
            in_urls[${#in_urls[@]}]="$1"
            shift
            ;;
    esac
done

if [ "$show_usage" = "yes" ] ; then
    usage
elif [ "$do_fetch" = "no" ] ; then
    extract_urls "${in_urls[@]}" | print_urls
else
    extract_urls "${in_urls[@]}" | fetch_urls "$use_dirs"
fi
