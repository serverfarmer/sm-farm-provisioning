#!/bin/bash
. /root/variables.sh

export SF_UNATTENDED=yes
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LC_ALL=C

if [ "`which apt-get`" != "" ]; then
	apt-get update
	if [ ! -s /etc/local/.config/upgrade.disable ]; then
		apt-get upgrade -y
	fi
	apt-get install -y git
elif [ "`which yum`" != "" ]; then
	yum install git
fi

git clone https://github.com/$SF_GITHUB/serverfarmer /opt/farm

base=`/opt/farm/config/get-url-extension-repositories.sh`
git clone "$base/sf-system" /opt/farm/ext/system
git clone "$base/sf-repos" /opt/farm/ext/repos
git clone "$base/sf-packages" /opt/farm/ext/packages
git clone "$base/sf-farm-roles" /opt/farm/ext/farm-roles
git clone "$base/sf-net-utils" /opt/farm/ext/net-utils
git clone "$base/sf-passwd-utils" /opt/farm/ext/passwd-utils

HOST=$1
OSVER=`/opt/farm/ext/system/detect-system-version.sh`
OSTYPE=`/opt/farm/ext/system/detect-system-version.sh -type`
HWTYPE=`/opt/farm/ext/system/detect-hardware-type.sh`

if [ ! -d /opt/farm/ext/farm-roles/lists/$OSVER ] && [ ! -h /opt/farm/ext/farm-roles/lists/$OSVER ]; then
	echo "error: something is wrong with operating system version, aborting install"
	exit 1
fi

. /opt/farm/ext/net-utils/functions

if [[ $HOST =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$ ]] || [ "`resolve_host $HOST`" = "" ]; then
	HOST=`hostname`
	echo "warning: given hostname $1 is invalid, continuing with the current server hostname $HOST"
fi

echo "HOST=$HOST" >/etc/farmconfig
echo "OSVER=$OSVER" >>/etc/farmconfig
echo "OSTYPE=$OSTYPE" >>/etc/farmconfig
echo "HWTYPE=$HWTYPE" >>/etc/farmconfig
echo "SMTP=true" >>/etc/farmconfig
echo "SYSLOG=true" >>/etc/farmconfig

mkdir -p   /etc/local/.config /etc/local/.ssh
chmod 0700 /etc/local/.config /etc/local/.ssh
chmod 0711 /etc/local

if [ "$FW_REPOSITORY" != "" ] && [ "$FW_SSH_KEY" != "" ]; then
	chmod 0600 /root/.ssh/id_github_firewall
	GIT_SSH=/opt/farm/scripts/git/helper.sh GIT_KEY=/root/.ssh/id_github_firewall git clone "$FW_REPOSITORY" /opt/farm/ext/firewall
fi

/opt/farm/ext/passwd-utils/create-group.sh newrelic 130  # common group for monitoring extensions
/opt/farm/setup.sh

/sbin/ifconfig -a |mail -s "Cloud instance $HOST setup finished" $SF_CONFIRM
