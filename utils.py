import os, sys

def eprint(*args, **kwargs):
    """
    Utility for printing to stderr.
    http://stackoverflow.com/a/14981125/758157
    """
    print(*args, file=sys.stderr, **kwargs)

def print_error_and_exit(*args, **kwargs):
    eprint(*args, **kwargs)
    sys.exit(-1)
