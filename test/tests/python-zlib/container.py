import zlib

assert(zlib.decompress(zlib.compress(b'IT WORKS IT WORKS IT WORKS')) == b'IT WORKS IT WORKS IT WORKS')
