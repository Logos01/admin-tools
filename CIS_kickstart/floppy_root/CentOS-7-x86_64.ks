
install
text
lang en_US.UTF-8
keyboard us
timezone America/Phoenix
auth --useshadow --enablemd5
selinux --enforcing
firewall --enabled
services --enabled=NetworkManager,sshd
eula --agreed
#ignoredisk --only-use=sda
reboot

%include /tmp/networking

%include /tmp/partitioning

rootpw --iscrypted <<ROOTPASS_HERE>>

repo --name=base --baseurl=http://mirror.cogentco.com/pub/linux/centos/7/os/x86_64/
#url --url="http://mirror.cogentco.com/pub/linux/centos/7/os/x86_64/"
cdrom

%packages --nobase --ignoremissing
@core
-aic94xx-firmware*
-alsa-*
-btrfs-progs
-cronie-anacron
-cronie
-dhclient
-ivtv-firmware
-iwl*firmware
-kexec-tools
-libertas-sd8686-firmware
-libertas-usb8388-firmware
-libertas-sd8787-firmware
-wpa_supplicant
aide
at
iptables-services
lsscsi
nc
nmap
ntp
ntpdate
openssh
openssh-client
openssh-server
policycoreutils
screen
sg3_utils
sysstat
tcpdump
tmux
vim
wget
yum
%end

%pre --log=/root/pre_log.1
mkdir -p /tmp/floppy
mount /dev/fd0 /tmp/floppy
%end

%pre --log=/root/pre_log.2

set -- `cat /proc/cmdline`
for I in $*; do case "$I" in *=*) eval $I;; esac; done

MEMTOT=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 ))
ROOTVG=${hname/\.*/}_vg

## 38+RAM GB minimum diskspace required for partitioning. Excess is delivered to /opt.
# CIS 1.1.6 Cannot be accomplished during "part" section of main kickstart. See %POST section.
# CIS 1.1.1-1.1.10 (Except as noted above)-> Create mountpoints with requisite mount options; resolved below. 
echo """
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=${MEMTOT}
part /boot --fstype ext4 --size=2048
part pv.01 --size=1 --grow
volgroup ${ROOTVG} pv.01
logvol /	--fstype ext4 --name=lv_root	--vgname=${ROOTVG}	--size=4096	--fsoptions='acl'
logvol /tmp	--fstype ext4 --name=lv_tmp	--vgname=${ROOTVG}	--size=4096	--fsoptions='acl,noexec,nodev,nosuid'
logvol /usr 	--fstype ext4 --name=lv_usr	--vgname=${ROOTVG}	--size=8192	--fsoptions='acl'
logvol /var 	--fstype ext4 --name=lv_var	--vgname=${ROOTVG}	--size=8192	--fsoptions='acl'
logvol /var/log	--fstype ext4 --name=lv_var_log	--vgname=${ROOTVG}	--size=4096	--fsoptions='acl'
logvol /home	--fstype ext4 --name=lv_home	--vgname=${ROOTVG}	--size=4096	--fsoptions='acl,noexec,nodev'
logvol /opt	--fstype ext4 --name=lv_opt	--vgname=${ROOTVG}	--size=4096	--grow --fsoptions='acl'
""" > /tmp/partitioning
%end

%pre --logfile=/root/pre_log.2

set -- `cat /proc/cmdline`
for I in $*; do case "$I" in *=*) eval $I;; esac; done

if [ "${netmask}" = "" ] ; then
    netmask="255.255.255.0"
fi

echo """
network	--device eth0 \
--bootproto static \
--ip=${ip} \
--netmask=${netmask} \
--gateway=${gateway} \
--nameserver=${nameserver} \
--hostname=${hostname} \
--activate
""" > /tmp/networking
#"""
%end


%post --logfile=/mnt/sysimage/root/post_log.1
#CIS 1.1.17 -> Set stickybit on all world-writable directories.
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs chmod a+t

#CIS 1.2 -> Configure system updates.
#Configure system to use Spacewalk server.
rpm -Uvh http://yum.spacewalkproject.org/2.3-client/RHEL/7/x86_64/spacewalk-client-repo-2.3-2.el7.noarch.rpm
BASEARCH=$(uname -i)
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin
rpm -Uvh http://<<SPACEWALK-SERVER-URL>>/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rhnreg_ks --serverUrl=https://<<SPACEWALK-SERVER-URL>>/XMLRPC --sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT --activationkey=1-centos7-x86_64

#CIS 1.3.2 -> Enable periodic invocation of AIDE daemon.
echo '#Ansible: run_aide_daemon' >> /var/spool/cron/root
echo '0 5 * * * /usr/sbin/aide --check' >> /var/spool/cron/root

#CIS 1.6.2 -> Enable Randomized Virtual Memory Region Placement
echo '''
#CIS 1.6.2 -> Enable Randomized Virtual Memory Region Placement
kernel.randomize_va_space = 2
''' >> /etc/sysctl.conf

#CIS 1.7 -> Use latest OS release
yum clean all ; yum update -y

#CIS 3.1 -> Set Daemon umask to 027.
echo '''
#CIS 3.1 -> Set Daemon Umask to 027.
umask 027
''' > /etc/sysconfig/init

#CIS 3.6 -> Configure NTP daemon
/sbin/chkconfig ntpd on

#CIS 3.16 -> Configure Postfix daemon
/sbin/chkconfig postfix on

#CIS 4.1.1->4.2.8 (See sysctl.conf added lines)
cat /mnt/floppy/sysctl.conf >> /etc/sysctl.conf

#CIS 4.4 -> IPv6
echo '''
#IPv6 Disabling
net.ipv6.conf.all.disable_ipv6=1 ''' >> /etc/sysctl.conf
#'''
sed -i '/AddressFamily/s/.*/AddressFamily inet/' /etc/ssh/sshd_config

[ -f /etc/centrify/ssh/sshd_config ] && \
sed -i '/AddressFamily/s/.*/AddressFamily inet/' /etc/centrify/ssh/sshd_config

#CIS 4.5.3 -> Verify Permissions on /etc/hosts.allow
[ -f /etc/hosts.allow ] && chmod 0644 /etc/hosts.allow
#CIS 4.5.5 -> Verify Permissions on /etc/hosts.deny
[ -f /etc/hosts.deny ] && chmod 0644 /etc/hosts.deny

#CIS 4.6.1 -> Disable DCCP
echo 'install dccp /bin/true' >> /etc/modprobe.d/CIS.conf
#CIS 4.6.2 -> Disable SCTP
echo 'install sctp /bin/true' >> /etc/modprobe.d/CIS.conf
#CIS 4.6.3 -> Disable RDS
echo 'install rds /bin/true' >> /etc/modprobe.d/CIS.conf
#CIS 4.6.4 -> Disable TIPC
echo 'install tipc /bin/true' >> /etc/modprobe.d/CIS.conf

#CIS 4.7 Enable firewalld
# Expects to will use 'old-style' iptables service.
mkdir -p /var/log/iptables
/bin/systemctl disable firewalld
/bin/systemctl enable iptables

#CIS 5.1.2 -> Enable rsyslogd Service
/bin/systemctl enable rsyslog

#CIS 5.2.2 -> Enable auditd Service
/bin/systemctl enable audit

#CIS 6.1.2 -> Enable crond daemon
/bin/systemctl enable crond

#CIS 6.1.4 -> Set User/Group Owner and Permission on /etc/crontab
#CIS 6.1.5 -> Set User/Group Owner and Permission on /etc/cron.hourly
#CIS 6.1.6 -> Set User/Group Owner and Permission on /etc/cron.daily
#CIS 6.1.7 -> Set User/Group Owner and Permission on /etc/cron.weekly
#CIS 6.1.8 -> Set User/Group Owner and Permission on /etc/cron.monthly
#CIS 6.1.9 -> Set User/Group Owner and Permission on /etc/cron.d
/bin/chown root:root /etc/cron{tab,.{hourly,daily,weekly,monthly,.d}}
/bin/chmod og-rwx /etc/cron{tab,.{hourly,daily,weekly,monthly,.d}}

#CIS 6.1.10 -> Restrict at Daemon
#CIS 6.1.11 -> Restrict at/cron to Authorized Users
/bin/rm /etc/at.deny /etc/cron.deny
echo 'root' > /etc/at.allow
echo 'root' > /etc/cron.allow
/bin/chown root:root /etc/at.allow /etc/cron.allow
/bin/chmod og-rwx /etc/at.allow /etc/cron.allow

#CIS 6.2.4 -> Disable SSH X11 Forwarding
sed -i '/X11Forwarding /s/.*/X11Forwarding yes/' /etc/ssh/sshd_config
#CIS 6.2.5 -> Set SSH MaxAuthTries to 4 or Less
sed -i '/MaxAuthTries/s/.*/MaxAuthTries 4/' /etc/ssh/sshd_config
#CIS 6.2.8 -> Disable SSH Root Login
sed -i '/PermitRootLogin/s/.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
#CIS 6.2.10 -> Do Not Allow Users to Set Environment Options
sed -i '/PermitUserEnvironment/s/.*/PermitUserEnvironment no/' /etc/ssh/sshd_config
#CIS 6.2.11 -> Use Only Approved Cipher in Counter Mode
sed -i '/# Ciphers and keying/s/a Ciphers aes128-ctr,aes192-ctr,aes256-ctr' /etc/ssh/sshd_config
#CIS 6.2.12 -> Set Idle Timeout Interval for User Login
sed -i '/ClientAliveInterval/s/.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i '/ClientAliveCountMax/s/.*/ClientAlivecountMax 0/' /etc/ssh/sshd_config

#CIS 6.2.13 -> Limit Access via SSH
echo '''
#CIS 6.2.13 -> Limit Access via SSH
AllowGroups root,ssh-users
DenyGroups  blacklist,anonymous
''' >> /etc/ssh/sshd_config
#'''

#CIS 6.2.14 -> Set SSH Banner
sed -i '/Banner/s/.*/Banner \/etc\/issue/' /etc/ssh/sshd_config

/usr/sbin/addgroup -g 501 l_sysadmins
/usr/sbin/addgroup -g 502 ssh-users
/usr/sbin/addgroup -g 503 blacklist
/usr/sbin/addgroup -g 504 anonymous

/usr/sbin/useradd -u 1001 -c "Local_Sysadmin_Account_for_Ian_Conrad" -G l_sysadmins,ssh-users -m -p '<<L_SYSADMIN_PASS_HASH>>' l_sysadmin

#CIS 6.3.1 -> Upgrade Password Hashing Algorithm to SHA-512
/sbin/authconfig --passalgo=sha512 --update

#CIS 6.5 -> Restrict Access to the su Command
sed -i '/auth required pam_wheel.so use_uid/s/.*/auth required pam_wheel.so use_uid/' /etc/pam.d/su

#CIS 7.4 -> Set Default umask for Users
sed -i 's/umask 022/umask 077/' /etc/bashrc
echo 'umask 077' >> /etc/profile.d/cis.sh

#CIS 7.5 -> Lock Inactive User Accounts
echo '#Ansible: lock_inactive_users' >> /var/spool/cron/root
echo '0 0 * * * /usr/sbin/useradd -D -f 35' >> /var/spool/cron/root

%end


%post --nochroot --logfile=/mnt/sysimage/root/post_log.2
#CIS 1.1.6 -> Set /var/tmp to bind mountpoint of /tmp in /etc/fstab.
echo "" >> /mnt/sysimage/etc/fstab
echo "/tmp	/var/tmp	none	bind	0 0" >> /mnt/sysimage/etc/fstab
#CIS 1.1.14-1.1.16 -> Configure mountpoints for /dev/shm in /etc/fstab
sed -i '/\/dev\/shm/s/defaults/nodev,nosuid,noexec,auto,nouser,async,relatime/' /mnt/sysimage/etc/fstab

#CIS 3.16 -> Configure postfix
for file in `ls /tmp/floppy/postfix`; do
    cp /tmp/floppy/postfix/${file} /mnt/sysimage/etc/postfix/${file}
done

#CIS 3.6 -> Configure NTP Daemon
cp /tmp/floppy/ntp.conf /mnt/sysimage/etc/ntp.conf
cp /tmp/floppy/ntpd /mnt/sysimage/etc/sysconfig/ntpd

#4.7 Enable firewalld
# Expects to will use 'old-style iptables service.
cp /tmp/floppy/sysconfig_iptables /mnt/sysimage/etc/sysconfig/iptables
cp /tmp/floppy/rsyslog_iptables.conf /mnt/sysimage/etc/rsyslog.d/iptables.conf
cp /tmp/floppy/logrotate_iptables.conf /mnt/sysimage/etc/logrotate.d/iptables.conf

#5.1.3 -> Configure rsyslog daemon
#5.1.5 -> Configure rsyslog to Send Logs to a Remote Log Host
cp /tmp/floppy/rsyslog.conf /mnt/sysimage/etc/rsyslog.conf

#5.2.x -> Configure System Accounting
mkdir -p /mnt/sysimage/etc/audit/
cp /tmp/floppy/auditd.conf /mnt/sysimage/etc/audit/auditd.conf
cp /tmp/floppy/audit.rules /mnt/sysimage/etc/audit/audit.rules
find /mnt/sysimage -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F path=" $1 " -F perm=x -F  auid>=1000 -F auid!=4294967295 -k privileged" }' > /tmp/5212_rules ; sed -i '/#CIS 5.2.12 -> Collect Use of Privileged  Commands/r /tmp/5212_rules' /mnt/sysimage/etc/audit/audit.rules

mkdir -m 0750 -p /mnt/sysimage/etc/sudoers.d
cp /tmp/floppy/l_sysadmins_sudoers /mnt/sysimage/etc/sudoers.d/999_l_sysadmins
chown root:root /mnt/sysimage/etc/sudoers.d/999_l_sysadmins
chmod 0750 /mnt/sysimage/etc/sudoers.d/999_l_sysadmins

mkdir -m 0700 -p /mnt/sysimage/root/.ssh
touch /mnt/sysimage/root/.ssh/authorized_keys
chmod 0600 /mnt/sysimage/root/.ssh/authorized_keys

for user in l_sysadmin ; do
    if [ -f /tmp/floppy/pubkeys/${user}.pub ] ; then
        mkdir -m 0700 -p /mnt/sysimage/home/${user}/.ssh
        cat /tmp/floppy/pubkeys/${user}.pub > /mnt/sysimage/home/${user}/.ssh/authorized_keys
        chmod 0600 /mnt/sysimage/home/${user}/.ssh/authorized_keys
        UID=$(awk -F':' "/${user}/ {print \$3}" /mnt/sysimage/etc/passwd)
        chown -R ${UID}:${UID} /mnt/sysimage/home/${user}
        cat /tmp/floppy/pubkeys/${user}.pub >> /mnt/sysimage/root/.ssh/authorized_keys
    fi
done



#CIS 6.3.2 -> Set Password Creation Requirement Parameters Using pam_pwquality
#CIS 6.3.3 -> Set Lockout for Failed Password Attempts
#CIS 6.3.4 -> Limit Password Reuse
cp /tmp/floppy/system-auth-ac /mnt/sysimage/etc/pam.d/system-auth-ac
cp /tmp/floppy/passwd-auth-ac /mnt/sysimage/etc/pam.d/passwd-auth-ac
cp /tmp/floppy/pwquality.conf /mnt/sysimage/etc/security/pwquality.conf

#CIS 7.1.1 -> Set Password Expiration Days
#CIS 7.1.2 -> Set Password Change Minimum Number of Days
#CIS 7.1.3 -> Set Password Expiring Warning Days
cp /tmp/floppy/login.defs /mnt/sysimage/etc/login.defs

#CIS 8.1 -> Set Warning Banner for Standard Login Services
#CIS 8.2 -> Remove OS Information from Login Warning Banners
cp /tmp/floppy/etc_issue /mnt/sysimage/etc/issue
( cd /mnt/sysimage/etc ; ln -s issue issue.net )
( cd /mnt/sysimage/etc ; ln -s issue motd )
chown 0:0 /mnt/sysimage/etc/issue
chmod 0644 /mnt/sysimage/etc/issue

%end



%post --nochroot
cp /root/pre_log* /mnt/sysimage/root/

echo '''
#####################################################################################
# CIS_CentOS_Linux_7_Benchmark_v1.1.0 compliant Kickstart profile
# Created 2015-09-17 by Logos01 <logos01 @ irc.freenode.net>
# Exceptions/caveats noted below:
#
# - CIS 1.1.8 -> Create Separate Partition for /var/log/audit. 
#     logrotate daemon used w/ compression, reducing logfile size.
#     nesting too many mountpoints can create system instability.
#
# - CIS 1.1.11-1.1.13 -> Removable media options
#     Disregarded for system flexibility. Connections are handled either by BIOS;
#     Or else by discretionary access (VMware/HP Chassis)
#
# - CIS 1.1.18-1.1.24 -> disable unnecessary filesystem types
#     System flexibility is an intentional choice. Post-deploy is an option.
#
# - CIS 1.4.x -> Install/configure SELinux
#     In Core install, no supplemental packages (like mcstrans) are installed.
#     Default profile for SELinux is "targeted"
#
# - CIS 1.5.3 -> Set Bootloader Password
#     System consoles only accessible via password-protected means (VM, Blade Chassis).
#
# - CIS 1.6.1 -> Restrict Core Dumps
#     Business processes require use of core dumps. Excluded/ignored.
#
# - CIS 2.1 -> Remove Legacy Services
#     Fulfilled by use of "@core" installation.
#
# - CIS 2.1.11 -> Remove xinetd
#     Multiple business processes require xinetd. 
#     Not installed in this profile, but will often be present.
#
# - CIS 3.2-3.11 -> Remove X Window System
#     Not installed by default. 
#     3.6 -> NTP *IS* complied with.
#
# - CIS 3.16 -> Configure Mail Transfer Agent for Local-Only Mode
#     Expects to use system emails for multiple business processes
#     This includes alerting/monitoring. Disregarded for that reason.
#
# - CIS 4.3 -> Wireless Networking
#     Expects to Servers do not have wireless networking hardware.
#
# - CIS 4.4 -> Configure IPv6
#     Expects to Servers will have IPv6 fully disabled.
#     There is no current plan to migrate the internal net to IPv6.
#
# - CIS 4.5 -> Install/Configure TCP Wrappers
#     This functionality will be handled via iptables.
# 
# - CIS 5.1.4 -> Create and Set permissions on rsyslog Log files
#     Handled by logrotate/rsyslog daemons.
#
# - CIS 5.1.6 -> Accept Remote rsyslog Messages Only on Designated Log Hosts
#     This kickstart is built for non-logging hosts.
#
# - CIS 5.3 -> Configure logrotate
#     Provided by vendor packaging defaults.
#
# - CIS 6.1.1 -> Configure anacron daemon
# - CIS 6.1.3 -> Set User/Group Owner and Permission on /etc/anacrontab
#     Electively noncompliant.
#     Expects to security stance is in concurrence with NSA Guidance:
#       cronie-anacron package adds no business functionality and represents a 
#       increased potential attack surface vector.
#
# - CIS 6.2.1 -> Set SSH Protocol to 2
# - CIS 6.2.2 -> Set LogLevel to INFO
# - CIS 6.2.3 -> Set Permissions on /etc/ssh/sshd_config
# - CIS 6.2.6 -> Set SSH IgnoreRhosts to Yes
# - CIS 6.2.7 -> Set SSH HostbasedAuthentication to No
# - CIS 6.2.9 -> Set SSH PermitEmptyPasswords to No
#     Provided by vendor packaging defaults.
#
# - CIS 6.2.8 -> Disable SSH Root Login
#     Password-based logins are disabled, however:
#     The need for direct root login on systems is present due to Expects to practices.
#     As such, only pubkey-based authentication will be effected.
#     A pubkey rotation standard will be implemented via configuration management.
#
# - CIS 6.4 -> Restrict root Login to System Console
#     This is controlled by access to virtualization / blade-chassis platforms.
#
# - CIS 7.2 -> Disable System Accounts
# - CIS 7.3 -> Default Group for root Account
#     Provided by vendor packaging defaults.
#
# - CIS 8.3 -> Set GNOME Warning Banner
#     GNOME not present in @core install.
#
# - CIS 9.1.1 -> Verify System File Permissions
# - CIS 9.1.2 -> Verify Permissions on /etc/passwd
# - CIS 9.1.3 -> Verify Permissions on /etc/shadow
# - CIS 9.1.4 -> Verify Permissions on /etc/gshadow
# - CIS 9.1.5 -> Verify Permissions on /etc/group
# - CIS 9.1.6 -> Verify User/Group Ownership on /etc/passwd
# - CIS 9.1.7 -> Verify User/Group Ownership on /etc/shadow
# - CIS 9.1.8 -> Verify User/Group Ownership on /etc/gshadow
# - CIS 9.1.9 -> Verify User/Group Ownership on /etc/group
#     Provided by vendor packaging defaults.
#
# - CIS 9.1.10 -> Find World Writable Files
# - CIS 9.1.11 -> Find Un-owned Files and Directories
# - CIS 9.1.12 -> Find Un-grouped Files and Directories
# - CIS 9.1.13 -> Find SUID System Executables
# - CIS 9.1.14 -> Find SGID System Executables
#     Any such files present at installation would be required for proper function.
#
# - CIS 9.2.1 -> Ensure Password Fields are Not Empty
# - CIS 9.2.2 -> Verify No Legacy "+" Entries Exist in /etc/passwd File
# - CIS 9.2.3 -> Verify No Legacy "+" Entries Exist in /etc/shadow File
# - CIS 9.2.4 -> Verify No Legacy "+" Entries Exist in /etc/group File
# - CIS 9.2.5 -> Verify No UID 0 Accounts Exist Other Than root
# - CIS 9.2.6 -> Ensure root PATH Integrity
# - CIS 9.2.7 -> Check Permissions on User Home Directories
# - CIS 9.2.8 -> Check User Dot File Permissions
# - CIS 9.2.9 -> Check Permissions on User .netrc Files
# - CIS 9.2.10 -> Check for Presence of User .rhosts Files
# - CIS 9.2.11 -> Check Groups in /etc/passwd
# - CIS 9.2.12 -> Check That Users Are Assigned Valid Home Directories
# - CIS 9.2.13 -> Check User Home Directory Ownership
# - CIS 9.2.14 -> Check for Duplicate UIDs
# - CIS 9.2.15 -> Check for Duplicate GIDs
# - CIS 9.2.16 -> Check That Reserved UIDs Are Assigned to System Accounts
# - CIS 9.2.17 -> Check for Duplicate User Names
# - CIS 9.2.18 -> Check for Duplicate Group Names
# - CIS 9.2.19 -> Check for Presence of User .netrc Files
# - CIS 9.2.20 -> Check for Presence of User .forward Files
#     Provided by vendor packaging defaults.
#
#####################################################################################
''' > /mnt/sysimage/root/CIS_notes.txt
%end
