#!/bin/sh
#usage: attachmail.sh 'user_name@company.com' 'Subject Here' file_to_attach 'This is the message body.'
#Invoke from the path in which file_to_attach resides.

gzip -c "$3" > "/tmp/$3.gz"
echo "$(base64 -w 0 /tmp/$3.gz)" > "/tmp/$3.gz"


echo "$(echo -n "From: " ; echo "$(whoami)@$(hostname)";
echo -n "To: "; echo -n "$1" ; echo -n '''
Mime-Version: 1.0
Content-Type: Multipart/Mixed; boundary="ATTACHMENT-BOUNDARY"
Return-Receipt-To: admin@company.com
Subject: ''' ; echo -n "$2" ; echo -n '''

--ATTACHMENT-BOUNDARY
Content-Disposition: inline;
Content-type: text/plain;

''' ; echo -n "$4" ; echo '''
--ATTACHMENT-BOUNDARY
Content-Disposition: attachment;
    filename="'''; echo -n "$3"; echo -n '''.gz"
Content-type: application/x-gzip;
    name="'''; echo -n "$3" ;echo '''.gz"
Content-Transfer-Encoding: base64

''' ; 
cat /tmp/$3.gz ; echo '''
--ATTACHMENT-BOUNDARY--
''')" | sendmail -t

rm -f "/tmp/$3.gz"
