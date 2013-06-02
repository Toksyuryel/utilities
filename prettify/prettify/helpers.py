from __future__ import unicode_literals

def read_leniently(in_file):
    current_line = ""
    at_eof = False

    while not at_eof:
        try:
            new_char = in_file.read(1)
            if new_char == "":
                at_eof = True
            elif new_char == '\n':
                yield current_line
                current_line = ""
            else:
                current_line += new_char
        except UnicodeDecodeError:
            in_file.seek(in_file.tell()+1)  # skip until we get a non-problem byte

    if current_line != "":
        yield current_line  # yield anything left over


def ignore_types_wrapper(reader, ignore_types):
    def type_ignoring_reader(ugly_log, reader_args):
        for line in reader(ugly_log, reader_args):
            if not type(line[1]) in ignore_types:
                yield line

    return type_ignoring_reader


def lenient_read_wrapper(reader):
    def lenient_reader(ugly_log, reader_args):
        return reader(read_leniently(ugly_log), reader_args)

    return lenient_reader


def center_plaintext(line, width=0):
    """Attempt to center a plaintext line, by determining terminal width.
    Alternatively, can be passed a width manually, and will center to that.
    Automatic method works only in Python 3.3 and up."""
    if width <= 0:  # manual width unset or invalid
        try:
            import shutil
            width = shutil.get_terminal_size(fallback=(0, 0)).columns
        except:
            pass

    if width <= 0:  # width still invalid
        return line
    elif len(line) > width:  # longer than terminal width, can't be centered
        return line
    else:
        return "{0}{1}".format(" " * ((width - len(line)) // 2), line)
