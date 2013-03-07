#!/usr/bin/env python
from __future__ import unicode_literals
from setuptools import setup, find_packages

setup(
        name = "prettify",
        version = "0.1.0",
        description = "IRC log prettifier",
        url = "https://pypi.python.org/pypi/prettify",

        packages = ["prettify", "prettify.reader", "prettify.renderer"],
        entry_points = {
            "console_scripts": ["prettify = prettify.app:run"]
            },

        author = "Bit Shift",
        author_email = "bitshift@bigmacintosh.net",

        classifiers = [
            "Programming Language :: Python",
            "Programming Language :: Python 3",
            "License :: OSI Approved :: BSD License",
            "Operating System :: OS Independent",
            "Development Status :: 4 - Beta",
            "Environment :: Console",
            "Intended Audience :: End Users/Desktop",
            "Topic :: Communications :: Chat :: Internet Relay Chat",
            "Topic :: Utilities",
            ]
)
