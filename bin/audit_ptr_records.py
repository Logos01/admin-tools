#!/usr/bin/python
###############################################################################
#
# /opt/scripts/admintools/audit-ptr-records.py
# Written 2012-03-28 by  Logos01 <logos01@nowhere>
# Usage:
#   ./audit-ptr-records.py 10.10.X.0 (Where X is specific subnet)
#
# Returns, per IP within the subnet, a comma-delimited list of the PTR records
#  Found for that IP assuming they are *both* not accessible to ping test 
#  And not found within ipplan.
#
###############################################################################


#----------------------------- ENVIRONMENT ------------------------------------
#-- All imported modules.----------
import xmlrpclib
import getpass
import StringIO
import sys
sys.path.append('/opt/scripts/lib')
from utils import shell
import subprocess
import socket
import re
#----------------------------------

#-------------------------- END ENVIRONMENT -----------------------------------


#------------------------------- Functions ------------------------------------

def check_environment():
    #Validates that the current user/host is jenkins/lpjensl01
    import getpass
    import socket
    import sys
    username = getpass.getuser()
    hostname = socket.gethostname()
    returnval = 0
    if not 'jenkins' in username:
        if not 'iconrad' in username:
            err = 'Please run this script as the Jenkins user. Exiting.'
            print >> sys.stderr, err
            returnval = 301
    if not 'lpjensl01' in hostname:
        err = 'This script is designed to be executed on lpjensl01. Exiting.'
        print >> sys.stderr, err
        returnval = 302
    return returnval

def prepare_host_lists(subnetstring,hostdict,hosts):
    # Returns 'working_subnet', 
    # determined by ipplan's baseaddr value for all subnets.
    import xmlrpclib
    import sys
    if not '/opt/scripts/lib' in sys.path:
        sys.path.append('/opt/scripts/lib')
    from utils import shell
    serverURL='REPLACEWITHREALHTTPURL'
    client = xmlrpclib.Server(serverURL)
    # '1' is the identifier for the LifeLock customer in ipplan.
    for subnet in client.ipplan.FetchBase(1,0,0,"",0,""):
        if subnet['baseaddr'] == subnetstring:
            baseindex = subnet['baseindex']
            working_subnet = client.ipplan.FetchSubnet(baseindex)
            for ip in working_subnet:
                ipaddr = ip['ipaddr']
                if ipaddr[-2:] == '.0':
                    pass
                else:
                    hnamelist = []
                    hnamecmd = 'dig +short -x %s'
                    hnamecmd = hnamecmd % ipaddr
                    hnamelist = shell(hnamecmd).run()
                    hnamelist = [ x for x in hnamelist \
                            if not 'Truncated' in x ]
                    hnamematches = 0
                    if ip['hname']:
                        for x in hnamelist:
                            if ip['hname'] in x:
                                hnamematches = 1
                        if not hnamematches:
                            hnamelist += [ip['hname']]
                    for hname in hnamelist:
                        hostdict[hname] = {}
                        hostdict[hname]['ipaddr'] = ipaddr
                        hosts += [hname]
    try:
        working_subnet
    except TypeError:
        exit_message = "Subnet %s not found in IPPlan for LifeLock customer."
        exit_message = exit_message % subnetstring
        print >> sys.stderr, exit_message
        sys.exit(1)
    if not hostdict:
        exit_message = "No in-use IP addresses found for %s subnet. Exiting."
        exit_message = exit_message % subnetstring
        sys.exit(0)
    hosts.sort()
    return working_subnet

def is_subnet_accessible(hosts,hostdict,subnetstring):
    #Checks if the current subnet is actually directly accessible.
    # Used to determine if a jumphost is needed to ping-scan the subnet.
    import re
    import sys
    if not '/opt/scripts/lib' in sys.path:
        sys.path.append('/opt/scripts/lib')
    from utils import shell
    accessible = 0
    #We attempt a 1-second delay ping on all hosts in the subnet
    # These are executed simultaneously.
    cmdstr = ''
    for host in hosts:
        cmdstr += "ping -c 1 -W 1 %s & " % host
    broadcastping = shell(cmdstr,shell=True).run()
    broadcastping = [ x for x in broadcastping if '64 bytes from' in x ]
    if  broadcastping:
        hname = broadcastping[0]
        hname = re.sub('64 bytes from ','',hname)
        hname = re.sub(' .*','',hname)
        for host in hosts:
            if host == hname:
                accessible = host
                break
        if hname and not accessible:
            accessible = 1
    return accessible

def update_ipdict(ip,pingcmd,hostdict):
    #Updates the ipdict dictionary with
    # values derived based on the working subnet.
    import sys
    import re
    if not '/opt/scripts/lib' in sys.path:
        sys.path.append('/opt/scripts/lib')
    from utils import shell
    pingval = shell(pingcmd).run()
    pingval = [ x for x in pingval if '64 bytes from' in x ]
    if pingval:
        ipdict[ip]['pings'] = 1
    else:
        ipdict[ip]['pings'] = 0
    match = 0
    for hname in ipdict[ip]['ptr']:
        try:
            if re.match(ip,hostdict[hname]['ipaddr']):
                match = 1
        except KeyError:
            pass
    if match:
        ipdict[ip]['ipplan'] = 1
    delval = 0
    if ipdict[ip]['ipplan'] == 1 \
        and ipdict[ip]['pings'] == 1 \
        and len(ipdict[ip]['ptr']) < 2:
            delval = 1
    if not ipdict[ip]['ptr']:
        delval = 1
    if delval:
        del ipdict[ip]

def accessible_subnet(hostdict,working_subnet):
    #Generates dns/ping commands for use w/ set_dict_values function.
    # For directly accessible subnets, this is trivial.
    import sys
    if not '/opt/scripts/lib' in sys.path:
        sys.path.append('/opt/scripts/lib')
    from utils import shell
    for ip in ipdict.keys():
        pingcmd = "ping -c 1 -W 2 %s"
        pingcmd = pingcmd % ip
        update_ipdict(ip,pingcmd,hostdict)


def non_accessible_subnet(hostdict,working_subnet,hosts):
    #Used to populate hostdict values for subnets which
    # are NOT directly accessible.
    # Scans hosts for accessible ssh jumphost in subnet by regex conversion.
    returnval = 0
    import re
    import sys
    import os
    if not '/opt/scripts/lib' in sys.path:
        sys.path.append('/opt/scripts/lib')
    from utils import shell
    import subprocess
    sshteststr = 'ssh '
    sshteststr += '-oPasswordAuthentication=no '
    sshteststr += '-oConnectTimeout=1 '
    sshteststr += '%s "echo `hostname`"'
    nctest = 'echo "hello" | nc -w 1 -vv %s 2>&1'

    #Regex conversion.
    rdict = {
            '-stg\.': '.',
            '-stg[0-9][0-9]': '',
            '-nfs': '',
            '-iscsi': '',
            '-mainvif-[0-9][0-9]': '',
            }
    robj = re.compile('|'.join(rdict.keys()))
    checkhosts= []
    for host in hosts:
        try:
            checkhost = robj.sub(lambda m: rdict[m.group(0)], host)
        except KeyError:
            #Some regexes fail on the -mainvif conversion when
            # Done in the above method. This is a workaround.
            checkhost = re.sub('-mainvif-[0-9][0-9]','',host)
        checkhosts += [checkhost]

    jumphost = 0
    for host in checkhosts:
        if not jumphost:
            #Port scanning port 22.
            sshtest = shell(nctest % host,shell=True).run()
            sshtest = [ x for x in sshtest if not 'refused' in x ]
            sshtest = [ x for x in sshtest if not 'timed out' in x ]
            if sshtest:
                #Attempting successful login for servers w/ 22 open.
                try:
                    sshhost = shell(sshteststr  % host).run(timeout=3)
                except subprocess.TimeoutExpired:
                    sshhost = []
                if sshhost:
                    jumphost = host

    if jumphost:
        home = os.environ["HOME"]
        user = os.environ["USER"]
        mastercmd = 'ssh'
        controlmaster = '-oControlMaster=%s ' % 'yes'
        controlpath = '-oControlPath=%s/.ssh/master-%s@%s:22 '
        controlpath = controlpath % (home,user,jumphost)
        mastercmd += controlmaster
        mastercmd += controlpath
        mastercmd += '"sleep 120" &'
        shell(mastercmd).run()
        #Actual set_dict_values generation here.
        for ip in ipdict.keys():
            jumpcmd = 'ssh %s %s %s "ping -c 1 -W 1 %s"'
            jumpcmd = jumpcmd % (controlmaster,controlpath,jumphost,ip)
            update_ipdict(ip,jumpcmd,hostdict)
    else:
        print >> sys.stderr, "No accessible jumphost found for subnet."
        returnval = 1

    return returnval

def sortprint():
    import StringIO
    mem = StringIO.StringIO()
    for i in range(1,256):
        for key,value in ipdict.items():
            if value['index'] == i:
                ptr = value['ptr']
                interpstring = '%-18s'
                toprint=[key]
                for x in ptr:
                    interpstring += ', %-28s'
                    toprint += [x]
                print >>mem, interpstring % tuple(toprint)

    output = mem.getvalue()
    maxindex = 0
    for line in output.split('\n'):
        index = line.count(',')
        if index > maxindex:
            maxindex = index
    header = "%-18s, %-28s" % ("IP Address:","PTR Record 1:")
    i = 1
    for n in range(1,maxindex):
        i += 1
        header += ', %-28s'
        newptr = "PTR Record %s:" % (i,)
        header = header % newptr
    print header
    print output

def noargs():
    import sys
    errstr = "This script expects a single subnet identifier"
    errstr += "('10.10.54.0') as its sole argument."
    print >> sys.stderr, errstr
    return 2

def main(argv=None):
    import xmlrpclib
    import sys
    sys.path.append('/opt/scripts/lib')
    from utils import shell
    import subprocess
    import socket
    import re

    socket.setdefaulttimeout(3)
    global returnval
    returnval = check_environment()

    if argv is None:
        try:
            argv = sys.argv[1:]
        except:
            returnval = noargs()

    if argv:
        global subnetstring
        subnetstring = argv[0]
        global working_subnet
        working_subnet = []
        global ipdict
        ipdict = {}
        hosts = []
        hostdict = {}
        subnetlist = []


        for i in range(1,256):
            currip = re.sub('0$',str(i),subnetstring)
            ipdict[currip] = {'index':i}
            ptrcmd = 'dig +short -x %s'
            ptrcmd = ptrcmd % currip
            currptr = shell(ptrcmd).run()
            currptr = [ x for x in currptr 
                    if not 'Truncated' in x ]
            ipdict[currip]['ptr'] = currptr
            ipdict[currip]['ipplan'] = 0
            ipdict[currip]['pings'] = 0

        working_subnet = prepare_host_lists(subnetstring,hostdict,hosts)
        subnet_scanned = 0
        if is_subnet_accessible(hosts,hostdict,subnetstring):
            accessible_subnet(hostdict,working_subnet)
        else:
            non_accessible_subnet(hostdict,working_subnet,hosts)

        if hostdict:
            subnet_scanned = 1

        sortprint()

    else:
        returnval = noargs()

    return returnval
#-------------------------- END FUNCTIONS -------------------------------------


#---------------------------    RUNTIME     -----------------------------------


if __name__ == "__main__":
    sys.exit(main())
#------------------------  END RUNTIME ----------------------------------------
