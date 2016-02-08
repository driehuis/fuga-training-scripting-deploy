#!/bin/bash

die() { echo "$@"; exit 1; }

match_image='ubuntu 14.04.3.*image'

set -eo pipefail

error_log=error.log
: >$error_log

_openstack() { set -e; echo "`date +%F-%T` openstack $@" >> $error_log; openstack "$@" 2>>$error_log; }

ubuntu_uuid="`_openstack image list | grep -i "$match_image"| awk '{print $2; }'|head -n1`"
[ -z "$ubuntu_uuid" ] && die "Could not find an image matching $match_image"
serverlist="`_openstack server list | awk '{print $4; }'`"
if [ "`echo \"$serverlist\" | grep -c '^scriptmaster'`" = "0" ]; then
    _openstack server create \
        --image $ubuntu_uuid \
        --flavor 'c1.tiny' \
        scriptmaster
    cnt=1
    while [ "`_openstack server show scriptmaster | grep -Ei '^..id[[:space:]]'|wc -l`" = "0" ]
    do
        sleep $cnt
        cnt=$(expr $cnt \* 2)
        [ $cnt -ge 120 ] && die "Host was not built in time"
    done
fi
scriptmaster_uuid="`_openstack server show scriptmaster | grep -Ei '^..id[[:space:]]' | awk '{print $4; }'`"
[ -z "$scriptmaster_uuid" ] && die "Could not find the instance uuid for scriptmaster"

# | 4e23dfd0-87d4-47fd-93dd-eb8d4a0385f5 | external | 185.54.112.187 | 172.17.1.134 | f738b479-e6fd-4035-aba2-3b0d9ef89a77 |
floating_ip="`_openstack ip floating list | grep "$scriptmaster_uuid"| awk '{print $6; }'|head -n1`"
if [ "$floating_ip" = "" ]; then
    free_ip_uuid="`_openstack ip floating list | grep "None"| awk '{print $2; }'|head -n1`"
fi
