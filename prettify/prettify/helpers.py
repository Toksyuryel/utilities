from __future__ import unicode_literals

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
