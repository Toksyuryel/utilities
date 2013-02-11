#!/usr/bin/env python
readers = {}
renderers = {}

def reader_function(reader_name, reader_desc="", reader_options=()):
    def decorate_reader(fn):
        readers[reader_name] = (fn, reader_desc, reader_options)
        return fn
    return decorate_reader

def renderer_function(renderer_name, renderer_desc="", renderer_options=()):
    def decorate_renderer(fn):
        renderers[renderer_name] = (fn, renderer_desc, renderer_options)
        return fn
    return decorate_renderer


@reader_function("weechat", "reads WeeChat logs")
def read_weechat(infile, args):
    for line in infile:
        if len(line.strip()) == 0:
            yield ("", "", "")
        else:
            line_parts = line.strip().split()
            yield (" ".join(line_parts[0:2]), line_parts[2],
                    " ".join(line_parts[3:]))


@renderer_function("plaintext", "emits reflowed plaintext",
        (('-1', '--single-pass', {
            'action': 'store_true',
            'dest': 'single_pass',
            'help': '''Skip
                the name-length-check pass. All names will be indented to the preset
                maximum name length. Required if operating in a pipeline.''',
            }),
         ('-m', '--max-name-length', {
             'action': 'store',
             'type': int,
             'default': 24,
             'dest': 'max_name_length',
             'help': '''Maximum name length - in single-pass mode, all
                names will be indented to this length. In two-pass mode, the
                name-length-check pass will terminate prematurely if this length is
                met or exceeded, allowing the first pass time to be shortened in
                some cases.''',
             }),
         ('-w', '--output-width', {
             'action': 'store',
             'type': int,
             'default': 80,
             'dest': 'page_width',
             'help': '''Width to reflow the log to.''',
             })
         ))
def render_plaintext(line_generator, args):
    max_name_length = args.max_name_length

    if args.single_pass:
        lines = line_generator
    else:
        lines = list(line_generator)
        preset_max_name_length = max_name_length
        max_name_length = 0
        for (timestamp, username, message) in lines:
            if len(username) >= preset_max_name_length:
                max_name_length = preset_max_name_length
            elif len(username) > max_name_length:
                max_name_length = len(username)

    for (timestamp, username, message) in lines:
        pretty_line = ""
        pretty_line += timestamp
        pretty_line += " " * (max_name_length - len(username) + 2)
        pretty_line += username
        pretty_line += " "
        remaining_line_length = args.page_width - (max_name_length + 3 + len(timestamp))
        message = message.split()
        while message != []:
            if len(message[0]) > remaining_line_length:
                if (len(message[0]) + max_name_length + 3 + len(timestamp)) > args.page_width:
                    pretty_line += " " + message[0]
                    message = message[1:]
                    remaining_line_length = 0
                else:
                    pretty_line += "\n" + (" " * (max_name_length + 3 + len(timestamp)))
                    remaining_line_length = args.page_width - (max_name_length + 3 + len(timestamp))
            else:
                pretty_line += " " + message[0]
                remaining_line_length -= len(message[0]) + 1
                message = message[1:]
        pretty_line += "\n"
        yield pretty_line


def prettify_log(ugly_log, reader, reader_args, renderer, renderer_args):
    return renderer(reader(ugly_log, reader_args), renderer_args)

if __name__ == '__main__':
    import argparse, sys

    parser = argparse.ArgumentParser(description='''Prettify an IRC log.''')
    parser.add_argument('-r', '--reader', action='store', default='weechat',
            choices=readers.keys(), help='''Reader to use for parsing the
            provided log.''', dest='reader')
    parser.add_argument('-rh', '--reader-help', action='store_true',
            help='''Show help for the active reader.''', dest='reader_help')
    parser.add_argument('-R', '--renderer', action='store', default='plaintext',
            choices=renderers.keys(), help='''Renderer to use for printing the
            prettified log.''', dest='renderer')
    parser.add_argument('-Rh', '--renderer-help', action='store_true',
            help='''Show help for the active renderer.''', dest='renderer_help')
    parser.add_argument('-i', '--input-file', action='store', default=sys.stdin,
            type=argparse.FileType('r'), help='''Log file to prettify (STDIN
            will be used if this is not given).''', dest="infile")
    parser.add_argument('-o', '--output-file', action='store',
            default=sys.stdout, type=argparse.FileType('w'), help='''Output file
            to write to (STDOUT will be used if this is not given).''',
            dest='outfile')
    args, unknown_args = parser.parse_known_args()

    reader_parser = argparse.ArgumentParser(description=readers[args.reader][1])
    for option in readers[args.reader][2]:
        reader_parser.add_argument(*option[:-1], **option[-1])
    if args.reader_help:
        reader_parser.parse_args(['-h'])
    else:
        reader_args, unknown_args = reader_parser.parse_known_args(unknown_args)

    renderer_parser = argparse.ArgumentParser(description=renderers[args.renderer][1])
    for option in renderers[args.renderer][2]:
        renderer_parser.add_argument(*option[:-1], **option[-1])
    if args.renderer_help:
        renderer_parser.parse_args(['-h'])
    else:
        renderer_args = renderer_parser.parse_args(unknown_args)

    if not (args.reader_help or args.renderer_help):
        for line in prettify_log(args.infile,
                readers[args.reader][0], reader_args,
                renderers[args.renderer][0], renderer_args):
            args.outfile.write(line)
