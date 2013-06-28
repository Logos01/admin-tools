#!/usr/bin/python

import os
import gnupg
import paramiko
import sys
import time

decrypted_pass = ''
chan = ''
try:
    host = sys.argv[1]
    user = sys.argv[2]
except IndexError:
    exitmsg = '''
    Usage: %s ${HOSTNAME/IP} ${USERNAME}
    Please ensure both arguments are valid and present.
    '''
    exitmsg = exitmsg % (sys.argv[0],)
    print >> sys.stderr, exitmsg
    sys.exit(1)
decrypted_root_pass = ''

def decryptPass():
    global decrypted_pass
    home = os.getenv('HOME')
    gpg = gnupg.GPG(gnupghome='%s/.gnupg/' % home)

    encrypted_pass = ''
    for x in open('%s/.ssh/passtext.gpg' % home,'r').readlines():
        encrypted_pass += x

    decrypted_pass = gpg.decrypt(encrypted_pass).data
    decrypted_pass = decrypted_pass.strip('\n')

def decryptRootPass():
    global decrypted_root_pass
    home = os.getenv('HOME')
    gpg = gnupg.GPG(gnupghome='%s/.gnupg/' % home)

    encrypted_pass = ''
    for x in open('%s/.ssh/pdcroot.txt.gpg' % home,'r').readlines():
        encrypted_pass += x

    decrypted_root_pass = gpg.decrypt(encrypted_pass).data

def runRemoteShell():
    global chan
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host,username=user,password=decrypted_pass)
    chan = ssh.invoke_shell()
    while not chan.recv_ready():
        print "Connecting..."
        time.sleep(2)
    print(chan.recv(1024))
    chan.send('sudo su -\n')
    time.sleep(1)
    chan.send('%s\n' % decrypted_pass)
    print(chan.recv(1024))
    exitstat = int(chan.exit_status_ready())
    print "Sudo invocation command exit status was: %s" % (exitstat)
    while not chan.recv_ready():
        time.sleep(2)
    chan.send('pwd\n')
    print(chan.recv(1024))
    print(chan.recv(1024))
    exitstat = int(chan.exit_status_ready())
    print "Exit status of last command was: %s" % (exitstat)
    chan.send('passwd\n')
    while not chan.recv_ready():
        time.sleep(2)
    chan.send(decrypted_root_pass)
    print(chan.recv(1024))
    while not chan.recv_ready():
        time.sleep(2)
    chan.send(decrypted_root_pass)
    print(chan.recv(1024))

def main():
    decryptPass()
    decryptRootPass()
    runRemoteShell()

if __name__ == "__main__":
    sys.exit(main())
