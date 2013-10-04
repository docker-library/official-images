#import atexit
import os
import threading

lockfiles = []


def init_task(fn, period, lockfile='/opt/stackbrew/brw.lock', logger=None):
    def periodic(logger):
        if logger is not None:
            logger.info('Periodic task started')
        threading.Timer(period, periodic, [logger]).start()
        fn()
    if os.path.exists(lockfile):
        raise RuntimeError('Lockfile already present.')
    open(lockfile, 'w').close()
    lockfiles.append(lockfile)
    threading.Timer(0, periodic, [logger]).start()


def clear_lockfiles(lockfiles):
    for lock in lockfiles:
        os.remove(lock)
    lockfiles = []

#atexit.register(clear_lockfiles, lockfiles)
