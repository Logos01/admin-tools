#! /bin/bash

case "$SSH_ORIGINAL_COMMAND" in
  *\&*|*\|*|*\;*|*\>*|*\<*|*\!*)
    exit 1
    ;;
  /usr/bin/rsync\ --server\ --sender*|rsync\ --server\ --sender*)
    sudo $SSH_ORIGINAL_COMMAND
    ;;
  /usr/bin/rsync*|rsync*)
    sudo $SSH_ORIGINAL_COMMAND
    ;;
  /sbin/zfs*|zfs*)
    ;;  
  *)
    exit 1
    ;;
esac
