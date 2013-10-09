import atexit
import os
import threading

lockfiles = []


def init_task(fn, period, lockfile='/opt/stackbrew/brw.lock', logger=None):
    def periodic(logger):
        if logger is not None:
            logger.info('Periodic task started')
        t = threading.Timer(period, periodic, [logger])
        t.daemon = True
        t.start()
        fn()
    if os.path.exists(lockfile):
        raise RuntimeError('Lockfile already present.')
    open(lockfile, 'w').close()
    lockfiles.append(lockfile)
    t = threading.Timer(0, periodic, [logger])
    t.daemon = True
    t.start()


def clear_lockfiles(lockfiles):
    for lock in lockfiles:
        os.remove(lock)


def on_exit(lockfiles):
    clear_lockfiles(lockfiles)

atexit.register(on_exit, lockfiles)
