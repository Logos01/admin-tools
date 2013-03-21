#!/usr/bin/python

import xmlrpclib
import sys
#Enables the use of the utils module, a wrapper for subprocess.Popen.
sys.path.append('/opt/scripts/lib')
from utils import shell
import subprocess
import re
import xtrace
from datetime import datetime,timedelta

global subnetstring
args = sys.argv[1:]
debug=0
hostprint = 0

for x in args:
    if '-d' in x:
        debug = 1
    if '-p' in x:
        hostprint = 1
args = [ x for x in args if not '-d' in x and not '-p' in x ]

hostdict = {}
global working_subnet
working_subnet = []
hosts = []
if debug:
    xtrace.start()

def prepare_host_lists(subnetstring,hostdict,hosts):
    serverURL='https://ipplan.internal.com/api/server.php'
    client = xmlrpclib.Server(serverURL)
    for subnet in client.ipplan.FetchBase(1,0,0,"",0,""):
        if subnet['baseaddr'] == subnetstring:
            baseindex = subnet['baseindex']
            working_subnet = client.ipplan.FetchSubnet(baseindex)
            for ip in working_subnet:
                if 'internal' in ip['hname']:
                    hname = ip['hname']
                    ipaddr = ip['ipaddr']
                    hostdict[hname] = {}
                    hostdict[hname]['ipaddr'] = ipaddr
                    hosts += [hname]
    try:
        working_subnet
    except TypeError:
        exit_message = "Subnet %s not found in IPPlan for internal customer." % subnetstring
        sys.exit(exit_message)
    hosts.sort()
    return working_subnet

def is_subnet_accessible(hosts,hostdict,subnetstring):
    accessible = 0
    cmdstr = ''
    for host in hosts:
        cmdstr += "ping -c 1 -W 1 %s & " % host
    broadcastping = shell(cmdstr,shell=True).run()
    broadcastping = [ x for x in broadcastping if '64 bytes from' in x ]
    ipaddr = broadcastping[0]
    ipaddr = re.sub('64 bytes from ','',ipaddr)
    ipaddr = re.sub(' .*','',ipaddr)
    for host in hosts:
        if hostdict[host]['ipaddr'] == ipaddr:
            accessible = host
            print accessible
            break
        else:
            accessible = 1
    return accessible

def accessible_subnet(hostdict,working_subnet):
    for ip in working_subnet:
        if 'internal' in ip['hname']:
            hname = ip['hname']
            ipaddr = ip['ipaddr']
            lastlogcmd = 'ssh -oPasswordAuthentication=no %s "lastlog"' % (hname)
            try:
                hostlastlog = shell(lastlogcmd).run(timeout=1)
                lastlogdict = {}
                for line in hostlastlog:
                    line = line.split(' ')
                    line = [ x for x in line if x ]
                    nologinevent = 0
                    for x in line:
                        if 'Never' in x:
                            nologinevent = 1
                    if nologinevent:
                        line = [ line[0], '', '', 'NOLOGIN']
                    lastlogdict[line[0]] = line[3:]
                hostdict[hname]['lastlog'] = lastlogdict
            except IndexError:
                hostdict[hname]['lastlog'] = {'NA': 'NA'}
            except subprocess.TimeoutExpired:
                hostdict[hname]['lastlog'] = {'NA': 'NA'}

def month_to_num(entry):
    months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    for i,month in enumerate(months,1):
        entry = entry.replace(month,str(i))
    return entry

for subnetstring in args:
    working_subnet = prepare_host_lists(subnetstring,hostdict,hosts)
    subnet_scanned = 0
    if is_subnet_accessible(hosts,hostdict,subnetstring):
        accessible_subnet(hostdict,working_subnet)
        subnet_scanned = 1
    else:
        subnet_scanned = 1

    userdict = {}
    overninety = datetime.date(datetime.now() - timedelta(days=90))
    if subnet_scanned:
        for hname,hdict in hostdict.items():
            try:
                for user,entry in hdict['lastlog'].items():
                    if not user == 'NA':
                        if not entry == ['NOLOGIN'] and not entry == ['Latest'] and entry:
                            try:
                                entry = datetime.date(datetime(int(entry[5]),int(month_to_num(entry[1])),int(entry[2])))
                            except IndexError:
                                print entry
                                entry = datetime.date(datetime(int(entry[4]),int(month_to_num(entry[0])),int(entry[1])))
                            if user not in userdict.keys():
                                userdict[user] = entry
                            if user in userdict.keys():
                                if userdict[user] < entry:
                                    userdict[user] = entry
            except AttributeError:
                pass

        users = userdict.keys()
        users.sort()

        for user in users:
            entry = userdict[user]
            if entry < overninety:
                print "%-20s: %-40s" % (user,entry)
if debug:
    xtrace.stop()
exit()
