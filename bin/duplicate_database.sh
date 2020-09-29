#!/bin/bash
####################################################################
#
# @Script: /usr/local/bin/duplicate_database.sh
# @Author: < Logos01 @ freenode >
# @Created: 2017-11-08
# @Description:
#  Script for duplicating a database instance on a server.
#   - Assumes existence of innobackupex-based single-database backup.
#   - Assumes backup has already had "--apply-log" executed against it.
#   - Assumes /root/.my.cnf is populated with root@localhost's password.
#   - Assumes that stored triggers and procedures in original database
#     have valid DEFINER values.
#  Hint:
#   /usr/sbin/innobackupex --include=${OLDDB} --rsync --parallel=$(grep CPU /proc/cpuinfo | wc -l) --export --user=${USER} --password=${PASSWORD}  ${IDBDIR}
#   /usr/sbin/innobackupex --apply-log --export ${IDBDIR}
#
#####################################################################

NEWDB="$1"
OLDDB="$2"
IDBDIR="$3"
TMPDIR="$(mktemp -d /tmp/duplicate.XXXXXXXXXXXX)"

mkdir -p "${TMPDIR}"

mysql -sNe "DROP DATABASE IF EXISTS ${NEWDB}"
mysql -sNe "CREATE DATABASE ${NEWDB}"
mysql -sNe "SELECT table_name FROM information_schema.tables WHERE table_schema='${OLDDB}' AND table_type != 'view';" > "${TMPDIR}/${OLDDB}_tables.txt"
mysql -sNe "SELECT table_name FROM information_schema.tables WHERE table_schema='${OLDDB}' AND table_type = 'view';" > "${TMPDIR}/${OLDDB}_views.txt"
mysql -sNe "SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema='${OLDDB}';" > "${TMPDIR}/${OLDDB}_triggers.txt"
mysql -sNe "SELECT routine_name FROM information_schema.routines WHERE routine_schema='${OLDDB}' AND routine_type = 'procedure';" > "${TMPDIR}/${OLDDB}_procedures.txt"
for tablename in $(cat "${TMPDIR}/${OLDDB}_tables.txt"); do
    mysql -sNe "CREATE TABLE ${NEWDB}.${tablename} LIKE ${OLDDB}.${tablename};";
done


#for viewname in $(cat "${TMPDIR}/${OLDDB}_views.txt"); do 
#    mysqldump --set-gtid-purged=OFF --no-create-db --no-create-info "${OLDDB}.${viewname}"
#    mysql -sNe "CREATE VIEW ${NEWDB}.${viewname} LIKE ${OLDDB}.${viewname};"; 
#done


mysql_dump_views(){
    mysql \
        --skip-column-names \
        --batch -e \
            "select table_name from information_schema.views \
            where table_schema = database()" $* \
        | xargs --max-args 1 mysqldump --set-gtid-purged=OFF --lock-tables=OFF --skip-opt $*
}

mysql_dump_views "${OLDDB}" > "${TMPDIR}/${OLDDB}_views.sql"

cat "${TMPDIR}/${OLDDB}_views.sql" | mysql "${NEWDB}"


mysqldump ${OLDDB} \
            --no-data \
            --no-create-db \
            --no-create-info \
            --triggers \
            --skip-opt \
            --lock-tables=OFF \
            --set-gtid-purged=OFF \
> "${TMPDIR}/${OLDDB}_triggers.sql" 2>&1

cat "${TMPDIR}/${OLDDB}_triggers.sql" | mysql "${NEWDB}"

mysqldump "${OLDDB}" \
            --no-data \
            --no-create-db \
            --no-create-info \
            --routines \
            --skip-triggers \
            --skip-opt \
            --lock-tables=OFF \
            --set-gtid-purged=OFF  \
> "${TMPDIR}/${OLDDB}_procedures.sql" 2>&1

cat "${TMPDIR}/${OLDDB}_procedures.sql" | mysql "${NEWDB}"

for tablename in $(cat "${TMPDIR}/${OLDDB}_tables.txt"); do
    mysql -sNe "ALTER TABLE ${NEWDB}.${tablename} DISCARD TABLESPACE;"
    rsync -av --progress "${IDBDIR}/${OLDDB}/${tablename}.ibd" "/var/lib/mysql/${NEWDB}/${tablename}.ibd"
    rsync -av --progress "${IDBDIR}/${OLDDB}/${tablename}.exp" "/var/lib/mysql/${NEWDB}/${tablename}.exp"
    chown mysql:mysql "/var/lib/mysql/${NEWDB}/${tablename}"*
    mysql -sNe "ALTER TABLE ${NEWDB}.${tablename} IMPORT TABLESPACE;"
done

rm -rf "${TMPDIR}"
