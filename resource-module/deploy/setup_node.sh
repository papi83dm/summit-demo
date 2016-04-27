#!/bin/bash
# usage: setup_node <node_ip>
set -x
log_file="/var/log/member_deploy_`date "+%Y-%m-%d-%T"`.log"
exec > ${log_file} 2>&1

cd $(dirname $0)

SSH='ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -i etc/id_rsa'
SCP='scp -o StrictHostKeyChecking=no -o ConnectTimeout=3 -i etc/id_rsa'

MGR_NAME=`hostname -s`
USER=ubuntu
META_INIT_SH=/opt/deploy/etc/init.sh
META_HOSTS=etc/hosts
SYS_HOSTS=/etc/hosts
ROLE=member

function update_hosts()
{
    local name=$1
    local ip=$2
    local fname=$3
    grep -q "$ip" $fname
    if [ "$?" != "0" ] ;then
       echo "$ip $name" >>$fname
    fi
}

function wait_server_ready()
{
    local conn=255
    local ip=$1
    # wait server ready
    while [ $conn -ne 0 ]; do
        echo $USER@${ip}
        $SSH $USER@${ip} true
        conn=$?
    done
}

function wait_minion_ready()
{
    local minion=$1
    while true; do
        echo "salt -t 2 $minion test.ping"
        (salt -t 2 $minion test.ping | grep True) && break
        sleep 0.5
    done
}

node_ip=$1

node_name=$(grep "$node_ip" $META_HOSTS|awk '{print $2}')
if [ -z $node_name ];then
    index=$((`cat ${META_HOSTS}| grep -v '^\#.*' | grep "${ROLE}[0-9]" |sort -u | wc -l` + 1 ))
    node_name=${ROLE}${index}
fi

# update node ip in etc/hosts
update_hosts $node_name $node_ip $META_HOSTS
update_hosts $node_name $node_ip $SYS_HOSTS

# clear old salt info
salt-key -d "$node_name" -y
ssh-keygen -f "/root/.ssh/known_hosts" -R "$node_ip"

# wait server is active
wait_server_ready $node_ip

# setup salt minion for node
cat $META_HOSTS | $SSH $USER@$node_ip "cat > /tmp/hosts"
cat $META_INIT_SH | $SSH $USER@$node_ip "cat > /tmp/init.sh; chmod a+x /tmp/init.sh"
cmd="sudo /tmp/init.sh $MGR_NAME $node_name"
$SSH $USER@$node_ip $cmd

# wait salt minion ready
wait_minion_ready $node_name

# deploy by salt
salt "${node_name}" state.sls docker

# set a web server
salt --async "${node_name}" state.sls web
exit 0
