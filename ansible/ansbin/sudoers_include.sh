#!/bin/sh

if [ "$(grep 'sudoers.d' /etc/sudoers)" = "" ]; then
    echo '' >> /etc/sudoers
    echo '#includedir /etc/sudoers.d' >> /etc/sudoers
fi

exit 0
