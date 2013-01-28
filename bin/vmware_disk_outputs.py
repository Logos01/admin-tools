#!/usr/bin/python
import xmlrpclib
import re, sqlite, sys, getpass
from optparse import OptionParser
from utils import shell

parser=OptionParser()
parser.add_option("-u","--username",dest="user",help="Satellite Username", metavar="USER")
parser.add_option("-s","--server",dest="server",help="Satellite Server hostname", metavar="SERVER")
parser.add_option("-p","--password",dest="password",help="Satellite User Password. If not given as argument, will be expected via prompt.", metavar="PASSWORD")
parser.add_option("-d","--database","--db",dest="database",help="destination database for audit results", metavar="DATABASE")
parser.add_option("-q","--quiet",action="store_false", dest="verbose", default=True,help="suppress stdout messages")

(options, args) = parser.parse_args()

errquit=''
toquit = 0

if not options.server: 
  errquit = errquit + "Satellite hostname required.\n"
  toquit = 1
if not options.user:
  errquit = errquit + "Satellite Username required.\n"
  toquit = 1
if not options.database:
  errquit = errquit + "SQLite database filename required.\n"
  toquit = 1

if toquit:
  parser.print_help()
  parser.error(errquit)


if not options.password:
  options.password = getpass.getpass('Enter password for USER: '.replace('USER',options.user))

shell('touch DB'.replace('DB',options.database)).run()

try:
  con = sqlite.connect(options.database) ;  cur = con.cursor()
  cur.execute('SELECT SQLITE_VERSION()') ;  data = cur.fetchone()
  print "SQLite Version: %s" % (data)

except sqlite.Error, e:
  print "Error %s:" % e.args[0] ; sys.exit(1)
  parser.print_help()


SATELLITE_URL= 'http://' + options.server + '/rpc/api'
SATELLITE_LOGIN=options.user
SATELLITE_PASSWORD=options.password 

client = xmlrpclib.Server(SATELLITE_URL, verbose=0)
key = client.auth.login(SATELLITE_LOGIN,SATELLITE_PASSWORD)


def vmwaretest(id):
  devices = client.system.getDevices(key,id)
  is_vmware = 0
  for device in devices:
    for dkey,dvalue in device.items():
      if re.match('VMware',str(dvalue)):
        is_vmware = 1
  return is_vmware


systemdict = {}
vmdict = {}

systemlist = client.system.listSystems(key)
for item in systemlist:
  systemdict[item['name']] = item['id']

for skey,svalue in systemdict.items():
  if vmwaretest(svalue):
    vmdict[skey] = True
  else:
    vmdict[skey] = False

cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
dbtables = cur.fetchone()


(has_hosts,has_df,has_fdisk) = (0,0,0)
if dbtables:
  for x in dbtables:
    if re.match('host',x):
      has_hosts = 1
    if re.match('df_out',x):
      has_df = 1
    if re.match('fdisk_out',x):
      has_fdisk = 1

if has_hosts: cur.execute('DROP TABLE hosts;')
if has_df: cur.execute('DROP TABLE df_out;')
if has_fdisk: cur.execute('DROP TABLE fdisk_out;')

cur.execute('CREATE TABLE hosts (Key INTEGER PRIMARY KEY, Hostname TEXT);')
cur.execute('CREATE TABLE df_out (Key INTEGER PRIMARY KEY, Hostname TEXT, df_out TEXT);')
cur.execute('CREATE TABLE fdisk_out (Key INTEGER PRIMARY KEY, Hostname TEXT, fdisk_out TEXT);')


for vkey,vvalue in vmdict.items():
  if vvalue == True:
    hostname = shell('ssh -q HOSTNAME "hostname"'.replace('HOSTNAME',vkey)).run()
    if hostname:
      diskfree_str = ''
      diskfree_out = shell('ssh -q HOSTNAME "df -h"'.replace('HOSTNAME',vkey)).run()
      for x in diskfree_out:
        diskfree_str = diskfree_str + x + '\n'
      fdisk_str = ''
      fdisk_out = shell('ssh -q HOSTNAME "fdisk -l"'.replace('HOSTNAME',vkey)).run()
      for x in fdisk_out:
        fdisk_str = fdisk_str + x + '\n'
      hostname = '\'HOSTNAME\''.replace('HOSTNAME',vkey)
      df_out = '''\'\'\'DF_OUT\'\'\''''.replace('DF_OUT',diskfree_str)
      fdisk_out = '''\'\'\'FDISK_OUT\'\'\''''.replace('FDISK_OUT',fdisk_str)
      cur.execute('insert into hosts(Hostname) VALUES (%s)' % (hostname))
      cur.execute('insert into df_out(Hostname,df_out) VALUES (%s,%s)' % (hostname,df_out))
      cur.execute('insert into fdisk_out(Hostname,fdisk_out) VALUES (%s,%s)' % (hostname,fdisk_out))
      con.commit()

con.commit()

client.auth.logout(key)