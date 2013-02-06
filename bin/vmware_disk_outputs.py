#!/usr/bin/python
import xmlrpclib
import sqlite
import sys
import getpass
from optparse import OptionParser
#utils module is expected to be stored in /usr/local/lib/python2.4
sys.path.append('/usr/local/lib/python2.4/')
from utils import shell

parser=OptionParser()
parser.add_option("-u","--username",dest="user",help="Satellite Username", metavar="USER")
parser.add_option("-s","--server",dest="server",help="Satellite Server hostname", metavar="SERVER")
parser.add_option("-p","--password",dest="password",help="Satellite User Password. If not given as argument, will be expected via prompt.", metavar="PASSWORD")
parser.add_option("-d","--database","--db",dest="database",help="destination database for audit results", metavar="DATABASE")
parser.add_option("-q","--quiet",action="store_false", dest="verbose", default=True,help="suppress stdout messages")

(options, args) = parser.parse_args()

errquit=[]

if not options.server:
    errquit.append("Satellite hostname required.")
if not options.user:
    errquit.append("Satellite Username required.")
if not options.database:
    errquit.append("SQLite database filename required.")

if errquit:
    parser.print_help()
    parser.error('\n'.join(errquit))


if not options.password:
    options.password = getpass.getpass('Enter password for %s: ' % options.user)

shell('touch %s' % options.database).run()

con = sqlite.connect(options.database)
cur = con.cursor()
cur.execute('SELECT SQLITE_VERSION()')
data = cur.fetchone()
print "SQLite Version: %s" % (data,)

SATELLITE_URL= 'http://' + options.server + '/rpc/api'
SATELLITE_LOGIN=options.user
SATELLITE_PASSWORD=options.password

client = xmlrpclib.Server(SATELLITE_URL, verbose=0)
key = client.auth.login(SATELLITE_LOGIN,SATELLITE_PASSWORD)

def vmwaretest(id):
    devices = client.system.getDevices(key,id)
    is_vmware = 0
    for device in devices:
        for dvalue in device.values():
            if 'VMware' in str(dvalue):
                return True
    return False


systemdict = {}
systemlist = client.system.listSystems(key)
for item in systemlist:
    systemdict[item['name']] = item['id']

vmdict = {}
for skey, svalue in systemdict.items():
    vmdict[skey] = vmwaretest(svalue)

ssh_out_dict = {}
ssh_events = []
for hostname, vvalue in vmdict.items():
    if not vvalue:
        continue

    current_run = shell('''ssh -oConnectTimeout=2 -q %s "hostname; echo '--DELIMITER1'; df -h ; echo '--DELIMITER2'; fdisk -l"''' % hostname).run()
    ssh_out_dict[hostname] = current_run


cur.execute('CREATE TABLE IF NOT EXISTS hosts (Key INTEGER PRIMARY KEY, Hostname TEXT);')
cur.execute('DELETE FROM hosts;')

cur.execute('''CREATE TABLE IF NOT EXISTS df_out (
    Key INTEGER PRIMARY KEY, 
    Hostname TEXT, 
    LogVolHome TEXT, 
    LogVolOpt TEXT, 
    LogVolRedhat TEXT, 
    LogVolRoot TEXT, 
    LogVolTmp TEXT, 
    LogVolUsr TEXT, 
    LogVolUsrLocal TEXT, 
    LogVolVar TEXT, 
    LogVolVarHttpd TEXT, 
    LogVolVarWWW TEXT, 
    df_out TEXT);''')
cur.execute('DELETE FROM df_out;')

cur.execute('CREATE TABLE IF NOT EXISTS fdisk_out (Key INTEGER PRIMARY KEY, Hostname TEXT, fdisk_out TEXT);')
cur.execute('DELETE FROM fdisk_out;')


for ssh_host, ssh_out in ssh_out_dict.items():
    lvhome_insert = None
    lvopt_insert = None
    lvredhat_insert = None
    lvroot_insert = None
    lvtmp_insert = None
    lvusr_insert = None
    lvusrlocal_insert = None
    lvvar_insert = None
    lvvarhttpd_insert = None
    lvvarwww_insert = None
    hostname = ssh_host
    try:
        delimita = ssh_out.index('--DELIMITER1')
        delimit1 = delimita + 1
        delimitb = ssh_out.index('--DELIMITER2')
        delimit3 = delimitb + 1
        df_delimited = ssh_out[delimit1:delimitb]
        fdisk_delimited = ssh_out[delimit3:]
    except ValueError:
        df_delimited = ['']
        fdisk_delimited = ['']
        
    for index, x in enumerate(df_delimited):
        xloc = index + 1
        y = str(x)
        if 'Home' in y: 
            lvhome_insert = df_delimited[xloc]
        if 'Opt' in y: 
            lvopt_insert = df_delimited[xloc]
        if 'Redhat' in y: 
            lvredhat_insert = df_delimited[xloc]
        if 'Root' in y: 
            lvroot_insert = df_delimited[xloc]
        if 'Tmp' in y: 
            lvtmp_insert = df_delimited[xloc]
        if 'Usr' in y and 'UsrLocal' not in y:
            lvusr_insert = df_delimited[xloc]
        if 'UsrLocal' in y:
            lvusrlocal_insert = df_delimited[xloc]
        if 'Var' in y and 'VarWWW' not in y and 'VarHttpd' not in y:
            lvvar_insert = df_delimited[xloc]
        if 'VarHttpd' in y: 
            lvvarhttpd_insert = df_delimited[xloc]
        if 'VarWWW' in y: 
            lvvarwww_insert = df_delimited[xloc]

    df_out = '\n'.join(df_delimited)

    fdisk_out = '\n'.join(fdisk_delimited)
        
    cur.execute("insert into hosts (Hostname) VALUES (%s)", (hostname,))
    cur.execute("""insert into df_out (
        Hostname, LogVolHome, LogVolOpt, LogVolRedhat, LogVolRoot, 
        LogVolTmp, LogVolUsr, LogVolUsrLocal, LogVolVar, LogVolVarHttpd, 
        LogVolVarWWW, df_out) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", (
            hostname, lvhome_insert, lvopt_insert, lvredhat_insert, 
            lvroot_insert, lvtmp_insert, lvusr_insert, lvusrlocal_insert, 
            lvvar_insert, lvvarhttpd_insert, lvvarwww_insert, df_out))
    cur.execute("insert into fdisk_out (Hostname, fdisk_out) VALUES (%s,%s)", (hostname,fdisk_out))
    con.commit()

client.auth.logout(key)
