#!/usr/bin/env python
from __future__ import unicode_literals
from prettify.app import register_renderer
from prettify import messages
import datetime

def render_plaintext(line_generator, args):  # TODO: rework for new format
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
        if args.keep_timestamp:
            timestamp += "  "
        else:
            timestamp = ""
        if not args.keep_date:
            timestamp = timestamp[11:]
        pretty_line = ""
        pretty_line += timestamp
        pretty_line += " " * (max_name_length - len(username))
        pretty_line += username
        pretty_line += " "
        remaining_line_length = args.page_width - (max_name_length + 1 + len(timestamp))
        message = message.split()
        while message != []:
            if len(message[0]) > remaining_line_length:
                if (len(message[0]) + max_name_length + 1 + args.indent_depth + len(timestamp)) > args.page_width:
                    pretty_line += " " + message[0]
                    message = message[1:]
                    remaining_line_length = 0
                else:
                    pretty_line += "\n" + (" " * (max_name_length + 1 + args.indent_depth + len(timestamp)))
                    remaining_line_length = args.page_width - (max_name_length + 1 + args.indent_depth + len(timestamp))
            else:
                pretty_line += " " + message[0]
                remaining_line_length -= len(message[0]) + 1
                message = message[1:]
        pretty_line += "\n"
        yield pretty_line

register_renderer(render_plaintext, "plaintext", "emits reflowed plaintext",
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
             }),
         ('-dd', '--drop-date', {
            'action': 'store_false',
            'dest': 'keep_date',
            'help': '''Drop the date portion of the timestamp. This is implied
                by --drop-timestamp, so only the latter is needed if both
                effects are desired.''',
            }),
         ('-dt', '--drop-timestamp', {
            'action': 'store_false',
            'dest': 'keep_timestamp',
            'help': '''Drop the timestamp, leaving just the log text. Implies
                --drop-date.''',
            }),
         ('-id', '--indent', {
             'action': 'store',
             'type': int,
             'default': 0,
             'dest': 'indent_depth',
             'help': '''Depth to indent continuation lines to.''',
             }),
        ))
