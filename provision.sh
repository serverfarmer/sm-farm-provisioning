#!/bin/bash
. /opt/farm/ext/net-utils/functions

if [ "$3" = "" ]; then
	echo "usage: $0 <[user@]hostname[:port]> <ssh-key-path> <profile>"
	exit 1
elif [ ! -f $2 ]; then
	echo "error: key not found"
	exit 1
elif [ ! -d /etc/local/.provisioning/$3 ]; then
	echo "error: profile directory not found"
	exit 1
fi

server=$1
tmpkey=$2
profile=$3

tmp=$server
login=""
port=22

if [ -z "${tmp##*@*}" ]; then
	login="${tmp%@*}"
	tmp="${tmp##*@}"
fi

if [ -z "${tmp##*:*}" ]; then
	port="${tmp##*:}"
	tmp="${tmp%:*}"
fi

host=$tmp
server=$host:$port

if [ "`resolve_host $host`" = "" ]; then
	echo "error: parameter $host not conforming hostname format, or given hostname is invalid"
	exit 1
elif grep -q "^$host:" ~/.serverfarmer/inventory/*.hosts || grep -q "^$host$" ~/.serverfarmer/inventory/*.hosts; then
	echo "error: host $host already added"
	exit 1
fi

if [ -z "$login" ]; then
	if [[ $host == *"amazonaws.com" ]] || [[ $host == *"bc.googleusercontent.com" ]]; then
		login="ubuntu"
	elif [[ $host == *"e24cloud.com" ]]; then
		login="e24"
	else
		login="root"
	fi
fi

ssh -i $tmpkey -p $port -o StrictHostKeyChecking=no -o PasswordAuthentication=no $login@$host uptime >/dev/null 2>/dev/null

if [[ $? != 0 ]]; then
	echo "error: host $host denied access"
	exit 1
fi

log=/var/log/provisioning/$host.log
echo "### BEGIN `date +'%Y-%m-%d %H:%M:%S'` ###" >>$log

# initial key is set only for ubuntu user - set it up also for root
if [ "$login" != "root" ]; then
	ssh -i $tmpkey -p $port $login@$host "cat /home/$login/.ssh/authorized_keys |sudo tee /root/.ssh/authorized_keys >/dev/null" >>$log
fi

. /etc/local/.provisioning/$profile/variables.sh

if [ "$FW_SSH_KEY" != "" ] && [ -f ~/.serverfarmer/ssh/$FW_SSH_KEY ]; then
	scp -i $tmpkey -P $port ~/.serverfarmer/ssh/$FW_SSH_KEY root@$host:/root/.ssh/id_github_firewall >>$log
fi

# copy setup scripts to provisioned host
scp -i $tmpkey -P $port /etc/local/.provisioning/$profile/variables.sh /opt/farm/mgr/farm-provisioning/resources/setup-server-farmer.sh root@$host:/root >>$log

# fix Google-related double repository definitions
if [[ $host == *"bc.googleusercontent.com" ]]; then
	ssh -i $tmpkey -p $port root@$host /bin/rm -f /etc/apt/sources.list.d/partner.list >>$log 2>>$log
fi

# install Server Farmer
ssh -i $tmpkey -p $port root@$host /root/setup-server-farmer.sh $host >>$log 2>>$log
ssh -i $tmpkey -p $port root@$host /bin/rm -f /root/variables.sh /root/setup-server-farmer.sh >>$log 2>>$log

if [ -x /opt/farm/mgr/farm-register/add-dedicated-key.sh ]; then
	/opt/farm/mgr/farm-register/add-dedicated-key.sh $server root >>$log 2>>$log
	/opt/farm/mgr/farm-register/add-dedicated-key.sh $server backup >>$log 2>>$log

	if [ -x /opt/farm/mgr/backup-collector/add-backup-host.sh ]; then
		/opt/farm/mgr/backup-collector/add-backup-host.sh $server >>$log 2>>$log
	fi

	echo $server >>~/.serverfarmer/inventory/cloud.hosts
fi

echo "### END `date +'%Y-%m-%d %H:%M:%S'` ###" >>$log
