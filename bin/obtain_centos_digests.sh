#!/bin/bash
ERRATADIR=/tmp/centos-errata
[ -d $ERRATADIR ] && rm -f $ERRATADIR/* || mkdir $ERRATADIR

(
   cd $ERRATADIR

   eval $(exec /bin/date -u +'yearmon=%Y-%B day=%d')
   # for the first day of the month: also consider last month
   # this only applies if the script is ran EVERY DAY
   if [ $day -lt $NBR_DIGESTS ]; then
      yearmon=$(date -u -d "$NBR_DIGESTS days ago" +%Y-%B)\ $yearmon
   fi

   # Use wget to fetch the errata data from centos.org
   listurl=http://lists.centos.org/pipermail/centos
   { for d in $yearmon; do
          wget --no-cache -q -O- $listurl/$d/date.html \
                | sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"
     done
   } |  tail -n $NBR_DIGESTS | xargs -n1 -I{} wget -q $listurl/{}

   # the ye old simple way, left as an example for reference:
   #wget --no-cache -q -O- http://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}
)
