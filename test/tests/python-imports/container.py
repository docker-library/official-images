import curses
import dbm
import readline

import bz2
assert(bz2.decompress(bz2.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import platform
if platform.python_implementation() != 'PyPy' and platform.python_version_tuple()[0] != '2':
    # PyPy and Python 2 don't support lzma
    import lzma
    assert(lzma.decompress(lzma.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import zlib
assert(zlib.decompress(zlib.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')
