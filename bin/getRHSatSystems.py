#!/usr/bin/python

import xmlrpclib
import getpass
from optparse import OptionParser
import sys

parser=OptionParser()
parser.add_option("-u","--username",dest="user",help="Satellite Username", metavar="USER")
parser.add_option("-s","--server",dest="server",help="Satellite Server hostname", metavar="SERVER")
parser.add_option("-p","--password",dest="password",help="Satellite User Password. If not given as argument, will be expected via prompt.", metavar="PASSWORD")
parser.add_option("-v","--quiet",action="store_true", dest="verbose", default=False,help="suppress stdout messages")

(options, args) = parser.parse_args()

errquit= []

if not options.server:
    errquit.append("Satellite hostname required.")
if not options.user:
    errquit.append("Satellite Username required.")

if errquit:
    parser.print_help()
    parser.error('\n'.join(errquit))

if not options.password:
    options.password = getpass.getpass('Enter password for %s: ' % options.user)

SATELLITE_URL = 'http://' + options.server + '/rpc/api'
SATELLITE_LOGIN = options.user
SATELLITE_PASSWORD = options.password

client = xmlrpclib.Server(SATELLITE_URL,verbose=options.verbose)

try:
    key = client.auth.login(SATELLITE_LOGIN,SATELLITE_PASSWORD)
except xmlrpclib.ProtocolError:
    print "Unable to authenticate to %s using credentials for %s user." % (options.server,options.user)	
    sys.exit(1)


systemlist = client.system.listSystems(key)
for x in systemlist:
    print x['name']

client.auth.logout(key)
sys.exit(0)
