import curses

import zlib
assert(zlib.decompress(zlib.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import bz2
assert(bz2.decompress(bz2.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')
