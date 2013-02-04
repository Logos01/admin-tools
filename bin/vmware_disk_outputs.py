#!/usr/bin/python
import xmlrpclib
import re
import sqlite
import sys
import getpass
import threading
import time
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
  con = sqlite.connect(options.database) ; cur = con.cursor()
  cur.execute('SELECT SQLITE_VERSION()') ; data = cur.fetchone()
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

ssh_out_dict = {}
ssh_events = []
loopcounter = 0
for vkey,vvalue in vmdict.items():
  if vvalue == True:
    hostname = vkey
    ssh_out_dict[hostname] = shell('ssh -oConnectTimeout=2 -q HOSTNAME "hostname; echo \'--DELIMITER1\'; df -h ; echo \'--DELIMITER2\'; fdisk -l"'.replace('HOSTNAME',hostname)).run()


cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
dbtables = cur.fetchall()

(has_hosts,has_df,has_fdisk) = (0,0,0)
if dbtables:
  for x in dbtables:
    if re.match('host',x[0]):
      has_hosts = 1
    if re.match('df_out',x[0]):
      has_df = 1
    if re.match('fdisk_out',x[0]):
      has_fdisk = 1

if has_hosts: cur.execute('DROP TABLE hosts;')
if has_df: cur.execute('DROP TABLE df_out;')
if has_fdisk: cur.execute('DROP TABLE fdisk_out;')

cur.execute('CREATE TABLE hosts (Key INTEGER PRIMARY KEY, Hostname TEXT);')
cur.execute('CREATE TABLE df_out (Key INTEGER PRIMARY KEY, Hostname TEXT, LogVolHome TEXT, LogVolOpt TEXT, LogVolRedhat TEXT, LogVolRoot TEXT, LogVolTmp TEXT, LogVolUsr TEXT, LogVolUsrLocal TEXT, LogVolVar TEXT, LogVolVarHttpd TEXT, LogVolVarWWW TEXT, df_out TEXT);')
cur.execute('CREATE TABLE fdisk_out (Key INTEGER PRIMARY KEY, Hostname TEXT, fdisk_out TEXT);')


for ssh_host,ssh_out in ssh_out_dict.items():
  lvhome_insert = 'NULL'
  lvopt_insert = 'NULL'
  lvredhat_insert = 'NULL'
  lvroot_insert = 'NULL'
  lvtmp_insert = 'NULL'
  lvusr_insert = 'NULL'
  lvusrlocal_insert = 'NULL'
  lvvar_insert = 'NULL'
  lvvarhttpd_insert = 'NULL'
  lvvarwww_insert = 'NULL'
  try:
    hostname = ssh_out[0]
  except IndexError:
    hostname = ssh_host
  try:
    delimita = ssh_out.index('--DELIMITER1')
    delimit1 = delimita + 1
    delimitb = ssh_out.index('--DELIMITER2')
    delimit2 = delimitb - 1
    delimit3 = delimitb + 1
    df_delimited = ssh_out[delimit1:delimit2]
    fdisk_delimited = ssh_out[delimit3:]
  except ValueError:
    df_delimited = ['']
    fdisk_delimited = ['']
  df_out = ''
  for x in df_delimited:
    df_out = df_out + x + '\n'
    if re.match('Home',x): lvhome_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Opt',x): lvroot_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Redhat',x): lvredhat_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Root',x): lvroot_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Tmp',x): lvtmp_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Usr',x) and not re.match('UsrLocal',x): lvusr_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('UsrLocal',x): lvusrlocal_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('Var',x) and not re.match('VarWWW',x) and not re.match('VarHttpd',x): lvvar_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('VarHttpd',x): lvvarhttpd_insert = df_delimited[df_delimited.index(x)+1]
    if re.match('VarWWW',x): lvvarwww_insert = df_delimited[df_delimited.index(x)+1]
  fdisk_out = ''
  for x in fdisk_delimited:
    fdisk_out = fdisk_out + x + '\n'
  cur.execute("insert into hosts(Hostname) VALUES ('%s')" % (hostname))
  cur.execute("insert into df_out(Hostname,LogVolHome,LogVolOpt,LogVolRedhat,LogVolRoot,LogVolTmp,LogVolUsr,LogVolUsrLocal,LogVolVar,LogVolVarHttpd,LogVolVarWWW,df_out) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')" % (hostname,lvhome_insert,lvopt_insert,lvredhat_insert,lvroot_insert,lvtmp_insert,lvusr_insert,lvusrlocal_insert,lvvar_insert,lvvarhttpd_insert,lvvarwww_insert,df_out))
  cur.execute("insert into fdisk_out(Hostname,fdisk_out) VALUES ('%s','%s')" % (hostname,fdisk_out))
  con.commit()

con.commit()

client.auth.logout(key)
