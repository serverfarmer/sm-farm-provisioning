#!/bin/bash
. /root/variables.sh

export SF_UNATTENDED=yes
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LC_ALL=C

if [ "`which apt-get`" != "" ]; then
	apt-get update
	apt-get upgrade -y
	apt-get install -y git
elif [ "`which yum`" != "" ]; then
	yum install git
fi

git clone https://github.com/$SF_GITHUB/serverfarmer /opt/farm

. /opt/farm/scripts/functions.custom

git clone "`extension_repositories`/sf-system" /opt/farm/ext/system
git clone "`extension_repositories`/sf-repos" /opt/farm/ext/repos
git clone "`extension_repositories`/sf-packages" /opt/farm/ext/packages
git clone "`extension_repositories`/sf-farm-roles" /opt/farm/ext/farm-roles
git clone "`extension_repositories`/sf-net-utils" /opt/farm/ext/net-utils
git clone "`extension_repositories`/sf-passwd-utils" /opt/farm/ext/passwd-utils

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

if [ "$FW_REPOSITORY" != "" ] && [ "$FW_SSH_KEY" != "" ] && [ -f /root/$FW_SSH_KEY ]; then
	mv -f /root/$FW_SSH_KEY /etc/local/.ssh/id_github_firewall
	chmod 0600 /etc/local/.ssh/id_github_firewall
	GIT_SSH=/opt/farm/scripts/git/helper.sh GIT_KEY=/etc/local/.ssh/id_github_firewall git clone "$FW_REPOSITORY" /opt/farm/ext/firewall
fi

/opt/farm/ext/passwd-utils/create-group.sh newrelic 130  # common group for monitoring extensions
/opt/farm/setup.sh

/sbin/ifconfig -a |mail -s "Cloud instance $HOST setup finished" $SF_CONFIRM
