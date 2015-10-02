#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
FORMAT="%F_%T"  # Customize timestamp format as desired, per `man date`
# %F_%T will lead to files like: audit.log.2015-02-26_15:43:46
COMPRESS=xz     # Change to bzip2 or xz as desired
KEEP=15         # Number of compressed log files to keep
rename_and_compress_old_logs() {
    for file in $(find /var/log/audit/ -name 'audit.log.[0-9]'); do
    timestamp=$(ls -l --time-style="+${FORMAT}" ${file} | awk '{print $6}')
    newfile=${file%.[0-9]}.${timestamp}
    # Optional: remove "-v" verbose flag from next 2 lines to hide output
    mv -v ${file} ${newfile}
    ${COMPRESS} -v ${newfile}
        done
}
delete_old_compressed_logs() {
    # Optional: remove "-v" verbose flag to hide output
        rm -v $(find /var/log/audit/ -regextype posix-extended -regex '.*audit\.log\..*(xz|gz|bz2)$' | sort -n | head -n -${KEEP})
}
rename_and_compress_old_logs
killall -USR1 auditd
rename_and_compress_old_logs
delete_old_compressed_logs
