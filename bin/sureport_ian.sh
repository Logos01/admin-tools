#!/bin/bash

cat /var/log/secure                                                    \
| awk '                                                                \
  /su | su: |SULOG:|sudo:/                                             \
  && !/pam_login_limit/                                                \
  && ( $6 !~ /pam_unix\(sudo:auth\)|pam_unix\(su:auth\)/ )             \
      '                                                                \
| tr -s ' '                                                            \
| sed                                                                  \
   -e 's/\[ID /[ID_/g'                                                 \
   -e 's/ auth\(.*\)\]/_auth\1]/g'                                     \
| awk '                                                                \
  {                                                                    \
    print $5 " || " $1 " " $2 " " $3 " || " $4 " || " $6 " || "        \
  } ;                                                                  \
  BEGIN {                                                              \
    OFS="" ;                                                           \
    ORS=""                                                             \
  } ;                                                                  \
  {                                                                    \
    for ( x=7; x<=NF; x++)                                             \
      print $x " "                                                     \
  } ;                                                                  \
  {                                                                    \
    print "\n"                                                         \
  }                                                                    \
      '                                                                \
| sort -nr
