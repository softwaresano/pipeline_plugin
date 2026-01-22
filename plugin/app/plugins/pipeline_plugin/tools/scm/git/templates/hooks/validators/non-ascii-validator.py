#!/usr/bin/python3

"""
require-ascii
"""

# http://python-future.org/compatible_idioms.html
from __future__ import print_function

import sys

status = 0

# https://theasciicode.com.ar/
MAX_ASCII_CODE = 255

# Allow Unicode characters in documentation files
UNICODE_ALLOWED_EXTENSIONS = ['.adoc', '.md', '.markdown', '.rst']

for filename in sys.argv:
    line_num = 0
    # Check if file extension allows Unicode
    allow_unicode = any(filename.endswith(ext) for ext in UNICODE_ALLOWED_EXTENSIONS)
    
    with open(filename, 'r', encoding='UTF-8') as fh:
        while True:
            line_num += 1
            try:
                # @todo This can probably be enhanced to read byte-by-byte
                # to report the offending column.
                line = fh.readline()
            except UnicodeDecodeError as e:
                print(f"{filename}: line {line_num} " + str(e))
                status = 1

            if not line:
                break

            col_num = 0
            for char in line:
                col_num += 1
                if ord(char) > MAX_ASCII_CODE and not allow_unicode:
                    print(
                        f"{filename}: line {line_num} column {col_num} " +
                        f"character \"{char}\" (decimal {ord(char)})"
                        )
                    status = 1

sys.exit(status)
