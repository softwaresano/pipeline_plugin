#!/usr/bin/python3

"""
require-ascii with icon/emoji allowlist
"""

# http://python-future.org/compatible_idioms.html
from __future__ import print_function

import sys
import unicodedata

status = 0

# https://theasciicode.com.ar/
MAX_ASCII_CODE = 255

# Allow Unicode characters in documentation files
UNICODE_ALLOWED_EXTENSIONS = ['']

# Allowed Unicode symbol ranges (emojis and icons)
ALLOWED_SYMBOL_RANGES = [
    (0x2600, 0x27BF),   # Miscellaneous Symbols and Dingbats
    (0x1F300, 0x1F9FF), # Emoticons, Symbols, Pictographs (emojis)
    (0x2300, 0x23FF),   # Miscellaneous Technical
    (0x2000, 0x206F),   # General Punctuation
]

# Allowed Unicode categories (Symbol and Punctuation)
ALLOWED_CATEGORIES = ['So', 'Sk', 'Sm', 'Sc', 'Po', 'Ps', 'Pe', 'Pi', 'Pf', 'Pd']

def is_allowed_unicode(char):
    """Check if character is an allowed icon/symbol"""
    code = ord(char)
    
    # Check if in allowed ranges
    for start, end in ALLOWED_SYMBOL_RANGES:
        if start <= code <= end:
            return True
    
    # Check Unicode category
    try:
        category = unicodedata.category(char)
        if category in ALLOWED_CATEGORIES:
            return True
    except:
        pass
    
    return False

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
                if ord(char) > MAX_ASCII_CODE:
                    # If file allows Unicode, check if it's an allowed icon/symbol
                    if allow_unicode and is_allowed_unicode(char):
                        continue
                    # Otherwise, reject the character
                    print(
                        f"{filename}: line {line_num} column {col_num} " +
                        f"character \"{char}\" (decimal {ord(char)})"
                        )
                    status = 1

sys.exit(status)
