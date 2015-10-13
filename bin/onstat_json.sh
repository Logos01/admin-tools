#!/bin/bash

source /usr/local/bin/Informix_profile

RAWFILE="/tmp/SERVERS$$.txt"
JSONFILE="/tmp/SERVERS$$.json"

onstat -g dis > "${RAWFILE}"

sed '/^IBM/s/.*//' "${RAWFILE}" >                            "${JSONFILE}"
sed -i '/^$/d'                                               "${JSONFILE}"
sed -i '/^There are/s/.*//'                                  "${JSONFILE}"
sed -i '/Server\s*:/s/.*:\s*\(.*\)/\1: {\nServer: \1/g'      "${JSONFILE}"
sed -i '/Host\s*:/s/$/\n}/g'                                 "${JSONFILE}"
sed -i '/:/s/^\s*/"/g'                                       "${JSONFILE}"
sed -i '/:/s/\s*:\s*/": "/g'                                 "${JSONFILE}"
sed -i '/:/s/\s*$/",/g'                                      "${JSONFILE}"
sed -i '/Host/s/,$//g'                                       "${JSONFILE}"
sed -i 's/\s\(Number\|Type\|Status\|Version\|Memory\)/_\1/g' "${JSONFILE}"
sed -i 's/}/},/g'                                            "${JSONFILE}"
sed -i 's/"{",/{/g'                                          "${JSONFILE}"
sed -i '$ s/,//'                                             "${JSONFILE}"

#cat "${JSONFILE}" | tr -d '\n'
echo '{'
cat "${JSONFILE}"
echo '}'
rm -f "${RAWFILE}" "${JSONFILE}"
