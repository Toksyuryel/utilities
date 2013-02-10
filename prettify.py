#!/usr/bin/env python
import sys

def prettify_line(timestamp, username, message, page_width, max_name_length):
    pretty_line = ""
    pretty_line += timestamp
    pretty_line += " " * (max_name_length - len(username) + 2)
    pretty_line += username
    pretty_line += " "
    remaining_line_length = page_width - (max_name_length + 3 + len(timestamp))
    while message != []:
        if len(message[0]) > remaining_line_length:
            if (len(message[0]) + max_name_length + 3 + len(timestamp)) > page_width:
                pretty_line += " " + message[0]
                message = message[1:]
                remaining_line_length = 0
            else:
                pretty_line += "\n" + (" " * (max_name_length + 3 + len(timestamp)))
                remaining_line_length = page_width - (max_name_length + 3 + len(timestamp))
        else:
            pretty_line += " " + message[0]
            remaining_line_length -= len(message[0]) + 1
            message = message[1:]
    pretty_line += "\n"
    return pretty_line

def prettify_log(ugly_log, page_width, single_pass, preset_max_name_length):
    try:
        ugly_log.seek(0, 0)
    except IOError:
        sys.stderr.write("WARNING: Couldn't seek in input, forcing single-pass mode.\n")
        single_pass = True

    max_name_length = 0

    if single_pass:
        max_name_length = preset_max_name_length
    else:
        for line in ugly_log:  # first pass, find max name length
            if len(line.strip()) == 0:
                continue
            line_parts = line.strip().split()
            if len(line_parts[2]) >= preset_max_name_length:
                max_name_length = preset_max_name_length
                break
            elif len(line_parts[2]) > max_name_length:
                max_name_length = len(line_parts[2])

        ugly_log.seek(0, 0)

    for line in ugly_log:  # second pass, actually format
        if len(line.strip()) == 0:
            yield prettify_line("", "", [], page_width, max_name_length)
            continue
        line_parts = line.strip().split()
        yield prettify_line(" ".join(line_parts[0:2]), line_parts[2],
                line_parts[3:], page_width, max_name_length)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='''Prettify an IRC log
            (currently only weechat format).''')
    parser.add_argument('-1', '--single-pass', action='store_true', help='''Skip
            the name-length-check pass. All names will be indented to the preset
            maximum name length. Required if operating in a pipeline.''',
            dest='single_pass')
    parser.add_argument('-m', '--max-name-length', action='store', default=24,
            type=int, help='''Maximum name length - in single-pass mode, all
            names will be indented to this length. In two-pass mode, the
            name-length-check pass will terminate prematurely if this length is
            met or exceeded, allowing the first pass time to be shortened in
            some cases.''', dest='max_name_length')
    parser.add_argument('-w', '--output-width', action='store', default=80,
            type=int, help='''Width to reflow the log to.''', dest='page_width')
    parser.add_argument('infile', action='store', nargs='?', default=sys.stdin,
            type=argparse.FileType('r'), help='''Log file to prettify (STDIN
            will be used if this is not given).''')
    parser.add_argument('-o', '--output-file', action='store',
            default=sys.stdout, type=argparse.FileType('w'), help='''Output file
            to write to (STDOUT will be used if this is not given).''',
            dest='outfile')
    args = parser.parse_args()

    for line in prettify_log(args.infile, args.page_width, args.single_pass,
            args.max_name_length):
        args.outfile.write(line)
