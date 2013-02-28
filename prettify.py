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


@renderer_function("html", "emits HTML",
        (('-t', '--timer', {
            'action': 'store_true',
            'dest': 'add_timer',
            'help': '''Include a javascript-based timer. Incurs some significant
                extra load time on long logs.''',
            }),
         ('-n', '--log-name', {
            'action': 'store',
            'dest': 'log_name',
            'default': 'Prettified Log',
            'help': '''Name to use for the log's title. If not provided,
            "Prettified Log" will be used.''',
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
        ))
def render_html(line_generator, args):
    yield '''<!doctype html>
<html lang="en">
<head>
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>''' + args.log_name + '''</title>
    <style type="text/css">
        body {
            padding: 2.5em;
        }
        h1 {
            margin-top: 0;
            font-size: 1.5em;
            text-align: center;
        }
        h1, .log {
            width: 100%;
        }
        .username {
            font-weight: bold;
        }
        .log {
            display: table;
        }
        .line {
            display: table-row;
            opacity: 1;
            -webkit-transition: opacity .3s ease-in;
            -moz-transition: opacity .3s ease-in;
            -o-transition: opacity .3s ease-in;
            transition: opacity .3s ease-in;
        }
        .line.timeHidden {
            opacity: 0;
        }
        .timestamp, .username, .message {
            display: table-cell;
            padding: 0.6em;
        }
        .line:nth-child(odd) {
            background-color: #e0dcdc;
        }
        .line:nth-child(even) {
            background-color: #f0ecec;
        }
        .timerLinks {
            position: fixed;
            top: 0.3em;
            left: 0.3em;
            background-color: #fff;
        }
        .timerLinks a {
            border: none;
            opacity: 0.4;
            -webkit-transition: opacity .3s ease-in;
            -moz-transition: opacity .3s ease-in;
            -o-transition: opacity .3s ease-in;
            transition: opacity .3s ease-in;
            margin: 0.2em;
        }
        .timerLinks a.active {
            opacity: 1;
        }
    </style>
</head>
<body>
    <h1>''' + args.log_name + '''</h1>
    <div class="log">
'''

    for (timestamp, username, message) in line_generator:
        yield '''        <div class="line">'''
        if args.keep_timestamp:
            yield '''            <span class="timestamp">'''
            if args.keep_date:
                yield timestamp
            else:
                yield timestamp[11:]
            yield '''</span>'''
        yield '''            <span class="username">'''
        if username == "*":
            yield '''</span>
            <span class="message"><strong>'''
            yield message.split()[0]
            yield '''</strong> '''
            yield " ".join(message.split()[1:])
        else:
            yield '''&lt;'''
            yield username
            yield '''&gt;</span>
            <span class="message">'''
            yield message
        yield '''</span>
        </div>
'''

    yield '''    </div>'''
    if args.add_timer:  # TODO: correctly handle date parsing in the case of --drop-(date|timestamp)
        yield '''    <script type="text/javascript">
        var timerLinks = document.createElement("div");
        var timedLink = document.createElement("a");
        var untimedLink = document.createElement("a");
        timedLink.href = "#timed";
        untimedLink.href = "#";
        timerLinks.textContent = "Timer:"
        timedLink.textContent = "On"
        untimedLink.textContent = "Off"
        timerLinks.classList.add("timerLinks");
        timerLinks.appendChild(timedLink);
        timerLinks.appendChild(untimedLink);
        document.body.appendChild(timerLinks);

        var lastTimer = null;
        var lines = document.getElementsByClassName("line");

        var parseDate = function(dateString) {
            var dateRegex = /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]{2}):([0-9]{2}):([0-9]{2})/;
            dateMatch = dateRegex.exec(dateString);
            if(dateMatch == null) {
                return null;
            } else {
                return new Date(
                        parseInt(dateMatch[1]),
                        parseInt(dateMatch[2]),
                        parseInt(dateMatch[3]),
                        parseInt(dateMatch[4]),
                        parseInt(dateMatch[5]),
                        parseInt(dateMatch[6]));
            }
        }

        var initFunction = function() {
            if(lastTimer != null) {
                clearTimeout(lastTimer);
            }

            if(location.hash == "#timed") {
                timedLink.classList.add("active");
                untimedLink.classList.remove("active");

                for(var i = 0; i < lines.length; i++) {
                    lines[i].classList.add("timeHidden");
                }

                var showNextLine = function() {
                    lines[this].classList.remove("timeHidden");
                    if(this < lines.length) {
                        setTimeout(showNextLine.bind(this+1), parseDate(lines[this+1].getElementsByClassName("timestamp")[0].textContent) - parseDate(lines[this].getElementsByClassName("timestamp")[0].textContent));
                    }
                };

                showNextLine.bind(0)();
            } else {
                untimedLink.classList.add("active");
                timedLink.classList.remove("active");

                for(var i = 0; i < lines.length; i++) {
                    lines[i].classList.remove("timeHidden");
                }
            }
        };

        window.addEventListener("hashchange", initFunction);
        initFunction();
    </script>
'''
    yield '''</body>
</html>'''


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
                if (len(message[0]) + max_name_length + 1 + len(timestamp)) > args.page_width:
                    pretty_line += " " + message[0]
                    message = message[1:]
                    remaining_line_length = 0
                else:
                    pretty_line += "\n" + (" " * (max_name_length + 1 + len(timestamp)))
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
