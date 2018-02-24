#!/bin/bash
. /opt/farm/scripts/functions.net

if [ "$3" = "" ]; then
	echo "usage: $0 <hostname> <ssh-key-path> <profile>"
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
elif [ "`cat /etc/local/.farm/*.hosts |grep \"^$1$\"`" != "" ]; then
	echo "error: host $1 already added"
	exit 1
fi


target=$1
tmpkey=$2
profile=$3

if [[ $target == *"amazonaws.com" ]]; then
	mode="ec2"
elif [[ $target == *"bc.googleusercontent.com" ]]; then
	mode="gce"
elif [[ $target == *"cloudapp.azure.com" ]]; then
	mode="azure"
elif [[ $target == *"e24cloud.com" ]]; then
	mode="e24"
else
	mode="generic"
fi

/opt/farm/ext/farm-provisioning/utils/upload.sh $target $tmpkey $profile $mode

if [ -x /opt/farm/ext/farm-manager/add-dedicated-key.sh ]; then
	/opt/farm/ext/farm-manager/add-dedicated-key.sh $target root
	/opt/farm/ext/farm-manager/add-dedicated-key.sh $target backup

	if [ -x /opt/farm/ext/backup-collector/add-backup-host.sh ]; then
		/opt/farm/ext/backup-collector/add-backup-host.sh $target
	fi

	echo $target >>/etc/local/.farm/cloud.hosts
fi
