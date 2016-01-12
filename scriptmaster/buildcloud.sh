#!/bin/sh

set -e

error_log=error.log
: >$error_log

_openstack() { (date +%F-%T; echo openstack "$@") > $error_log;  openstack "$@" 2> $error_log ; }

serverlist="`_openstack server list | grep -Ev -- '(------|Name.*Status)' | awk '{print $4; }'`"
if [ "`echo \"$serverlist\" | grep -c '[[:space:]]scriptmaster'`" = "0" ]; then
    _openstack server create \
        --image 66138755-6339-455c-98a3-ce0849e9dd50 \
        --flavor 'c1.tiny' \
        scriptmaster
fi
