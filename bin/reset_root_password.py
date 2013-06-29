#!/usr/bin/python

import os
import gnupg
import paramiko
import sys
import time

decrypted_pass = ''
decrypted_root_pass = ''
host = ''
user = ''

def decryptPass():
    global decrypted_pass
    home = os.getenv('HOME')
    gnupghome = '%s/.gnupg/' % home
    passfile = '%s/.ssh/passtext.gpg' % home
    gpg = gnupg.GPG(gnupghome=gnupghome)

    encrypted_pass = open(passfile,'r').read()

    decrypted_pass = gpg.decrypt(encrypted_pass).data
    decrypted_pass = decrypted_pass.strip('\n')

def decryptRootPass():
    global decrypted_root_pass
    home = os.getenv('HOME')
    gnupghome = '%s/.gnupg/' % home
    passfile = '%s/.ssh/pdcroot.txt.gpg' % home
    gpg = gnupg.GPG(gnupghome=gnupghome)

    encrypted_pass = open(passfile,'r').read()

    decrypted_root_pass = gpg.decrypt(encrypted_pass).data

def runRemoteShell():
    user = sys.argv[2]
    host = sys.argv[1]
    global decrypted_pass
    global decrypted_root_pass
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
    while not chan.recv_ready():
        time.sleep(2)
    chan.send('pwd\n')
    print chan.recv(1024)
    chan.send('passwd\n')
    while not chan.recv_ready():
        time.sleep(2)
    chan.send(decrypted_root_pass)
    print chan.recv(1024)
    while not chan.recv_ready():
        time.sleep(2)
    chan.send(decrypted_root_pass)
    print chan.recv(1024)

def main():
    try:
        decryptPass()
        decryptRootPass()
        runRemoteShell()
        return 0
    except IndexError:
        exitmsg = '''
        Usage: %s ${HOSTNAME/IP} ${USERNAME}
        Please ensure both arguments are valid and present.
        '''
        exitmsg = exitmsg % (sys.argv[0],)
        print >> sys.stderr, exitmsg
        return 1


if __name__ == "__main__":
    sys.exit(main())
