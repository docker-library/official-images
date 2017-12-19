import threading
import sys


def fun(i):
    try:
        fun(i+1)
    except:
        sys.exit(0)


t = threading.Thread(target=fun, args=[1])
t.start()
