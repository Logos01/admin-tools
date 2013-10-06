#!/usr/bin/python

import sys

class user:
    old = ''
    current = ''
    new = ''
    home = ''
    uid = ''   #User ID Number goes here.
    if not isinstance(uid, int):
        try:
            uid = int(uid)
        except:
            print >> sys.stderr, "uid provided is a non-number. Quitting."
            exit(1)

def get_values():
    import pwd
    pwdall = pwd.getpwall()
    uidpw=[]
    retval = 0
    for x in pwdall:
        if user.old in x:
            uidpw = x
    if not uidpw:
        uidpw= [ '','','','','','']
    (user.current,user.home) = (uidpw[0],uidpw[5])

def set_values():
    import subprocess
    import shlex
    from subprocess import call,PIPE
    retval = 0
    command = '/usr/sbin/usermod -l %s -d /home/%s -m %s'
    command = command % (
        user.new,
        user.new,
        user.current
    )
    command = shlex.split(command)
    if not user.current == user.new:
        retval = call(command,stdout=PIPE,stderr=PIPE)
    return retval

def main():
    get_values()
    retval = set_values()
    return retval

if __name__ == "__main__":
    sys.exit(main())
