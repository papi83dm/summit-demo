#!/bin/bash

cd $(dirname $0)
exec 2>&1 > /var/log/bootstrap.log
SSH='ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -i etc/id_rsa'
SCP='scp -o StrictHostKeyChecking=no -o ConnectTimeout=3 -i etc/id_rsa'
META_INIT_SH=/opt/deploy/etc/init.sh
META_HOSTS=etc/hosts
chmod +x $META_INIT_SH
$META_INIT_SH salt salt
