#!/usr/bin/env python

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

def prettify_log(ugly_log, page_width):
    if isinstance(ugly_log, str):
        try:
            import cStringIO
            ugly_log = cStringIO.StringIO(ugly_log)
        except ImportError:
            import io
            ugly_log = io.StringIO(ugly_log)

    max_name_length = 0

    for line in ugly_log:  # first pass, find max name length
        if len(line.strip()) == 0:
            continue
        line_parts = line.strip().split()
        if len(line_parts[2]) > max_name_length:
            max_name_length = len(line_parts[2])

    ugly_log.seek(0, 0)
    for line in ugly_log:  # second pass, actually format
        if len(line.strip()) == 0:
            yield prettify_line("", "", [], page_width, max_name_length)
            continue
        line_parts = line.strip().split()
        yield prettify_line(" ".join(line_parts[0:2]), line_parts[2], line_parts[3:], page_width, max_name_length)

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 2:
        for line in prettify_log(sys.stdin.read(), int(sys.argv[1])):
            sys.stdout.write(line)
    elif len(sys.argv) == 3:
        for line in prettify_log(open(sys.argv[1], "r"), int(sys.argv[2])):
            sys.stdout.write(line)
    else:
        sys.stderr.write("Wrong number of arguments. Syntax is `{0} [FILE] WIDTH`, where data will be read from stdin if no [FILE]".format(sys.argv[0]))
