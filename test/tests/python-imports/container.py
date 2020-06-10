import platform

isWindows = platform.system() == 'Windows'
isNotPypy = platform.python_implementation() != 'PyPy'
isCaveman = platform.python_version_tuple()[0] == '2'

if not isWindows:
    import curses
    import readline

    if isCaveman:
        import gdbm
    else:
        import dbm.gnu

        if isNotPypy:
            # PyPy and Python 2 don't support lzma
            import lzma
            assert(lzma.decompress(lzma.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import bz2
assert(bz2.decompress(bz2.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import zlib
assert(zlib.decompress(zlib.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

if not isCaveman:
    import lzma
    assert(lzma.decompress(lzma.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')
