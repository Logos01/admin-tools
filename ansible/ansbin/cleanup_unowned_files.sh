#!/bin/bash


_cleanup_dir(){
    cd ${directory}

    find . -maxdepth 1 -nouser -exec echo "{}" + |\
    sed 's@./@@g' | sed 's@ @\n@g' |\
    while read user ; do
	if [[ "$(net ads search samAccountName=${user} -P)" != "Got 0 replies" ]]; then
	    chown_target="${user}:${group_val}"
            chown -R "${chown_target}" ${user}
	fi
    done
    retval=$?
    return ${retval}
}

_cleanup_home(){
    directory="/home"
    group_val="domain users"
    _cleanup_dir
}

_cleanup_mail(){
    directory="/var/spool/mail"
    group_val="mail"
    _cleanup_dir
}

_main(){
    _cleanup_home
    homeret=$?
    _cleanup_mail
    mailret=$?
    exit $(( homeret + mailret ))
}

_main
