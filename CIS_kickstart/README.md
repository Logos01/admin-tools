Anonymized and Tokenized kickstart profile for CentOS 7.

Written to be compliant with CIS Benchmark v1.1.0 Guidelines for CentOS 7 x86_64.

Current notes: 
* Expects a Spacewalk server to register to / update against.
* Has not been tested.
* Provided as-is.


Usage:
With an install DVD, append the following to the linux kernel parameters before install.  Should run fully unattended.

ip=${IPv4_ADDRESS} netmask=${4_OCTET_NOTATION_NETMASK} gateway=${IPv4_GATEWAY} hostname=${FULLY_QUALIFIED_HOSTNAME} nameserver=${IPv4_DNS_SERVER_IP} ks=floppy:/CentOS-7-x86_64.ks
