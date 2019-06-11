#!/bin/bash
. /opt/farm/ext/net-utils/functions

if [ "$3" = "" ]; then
	echo "usage: $0 <hostname[:port]> <ssh-key-path> <profile>"
	exit 1
elif [ "`resolve_host $1`" = "" ]; then
	echo "error: parameter $1 not conforming hostname format, or given hostname is invalid"
	exit 1
elif [ ! -f $2 ]; then
	echo "error: key not found"
	exit 1
elif [ ! -d /etc/local/.provisioning/$3 ]; then
	echo "error: profile directory not found"
	exit 1
elif grep -q "^$1:" /etc/local/.farm/*.hosts || grep -q "^$1$" /etc/local/.farm/*.hosts; then
	echo "error: host $1 already added"
	exit 1
fi


server=$1
tmpkey=$2
profile=$3

if [ -z "${server##*:*}" ]; then
	host="${server%:*}"
	port="${server##*:}"
else
	host=$server
	port=22
fi


login="root"
is_gce=""

if [[ $host == *"amazonaws.com" ]]; then
	login="ubuntu"
elif [[ $host == *"bc.googleusercontent.com" ]]; then
	login="ubuntu"
	is_gce="true"
elif [[ $host == *"e24cloud.com" ]]; then
	login="e24"
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

if [ "$FW_SSH_KEY" != "" ] && [ -f /etc/local/.ssh/$FW_SSH_KEY ]; then
	scp -i $tmpkey -P $port /etc/local/.ssh/$FW_SSH_KEY root@$host:/root >>$log
fi

# copy setup scripts to provisioned host
scp -i $tmpkey -P $port /etc/local/.provisioning/$profile/variables.sh /opt/farm/ext/farm-provisioning/resources/setup-server-farmer.sh root@$host:/root >>$log

# fix Google-related double repository definitions
if [ "$is_gce" != "" ]; then
	ssh -i $tmpkey -p $port root@$host /bin/rm -f /etc/apt/sources.list.d/partner.list >>$log 2>>$log
fi

# install Server Farmer
ssh -i $tmpkey -p $port root@$host /root/setup-server-farmer.sh $host >>$log 2>>$log
ssh -i $tmpkey -p $port root@$host /bin/rm -f /root/variables.sh /root/setup-server-farmer.sh >>$log 2>>$log

if [ -x /opt/farm/ext/farm-manager/add-dedicated-key.sh ]; then
	/opt/farm/ext/farm-manager/add-dedicated-key.sh $server root >>$log 2>>$log
	/opt/farm/ext/farm-manager/add-dedicated-key.sh $server backup >>$log 2>>$log

	if [ -x /opt/farm/ext/backup-collector/add-backup-host.sh ]; then
		/opt/farm/ext/backup-collector/add-backup-host.sh $server >>$log 2>>$log
	fi

	echo $server >>/etc/local/.farm/cloud.hosts
fi

echo "### END `date +'%Y-%m-%d %H:%M:%S'` ###" >>$log
