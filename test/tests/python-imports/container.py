import platform, sys

isWindows = platform.system() == 'Windows'
isNotPypy = platform.python_implementation() != 'PyPy'
isCaveman = sys.version_info[0] == 2

if not isWindows:
    import curses
    import readline

    if isCaveman:
        import gdbm
    else:
        import dbm.gnu
        import dbm.ndbm

import bz2
assert(bz2.decompress(bz2.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

import zlib
assert(zlib.decompress(zlib.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

if not isCaveman:
    import lzma
    assert(lzma.decompress(lzma.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')

    # https://github.com/docker-library/python/pull/954
    shouldHaveSetuptoolsAndWheel = sys.version_info[0] == 3 and sys.version_info[1] < 12
    import importlib.util
    hasSetuptools = importlib.util.find_spec('setuptools') is not None
    hasWheel = importlib.util.find_spec('wheel') is not None
    assert(hasSetuptools == shouldHaveSetuptoolsAndWheel)
    assert(hasWheel == shouldHaveSetuptoolsAndWheel)
