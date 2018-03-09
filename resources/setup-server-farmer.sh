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
. /opt/farm/scripts/functions.net

git clone "`extension_repositories`/sf-system" /opt/farm/ext/system
git clone "`extension_repositories`/sf-repos" /opt/farm/ext/repos

HOST=$1
OSVER=`/opt/farm/ext/system/detect-system-version.sh`
OSTYPE=`/opt/farm/ext/system/detect-system-version.sh -type`
HWTYPE=`/opt/farm/ext/system/detect-hardware-type.sh`

if [ ! -d /opt/farm/ext/repos/lists/$OSVER ] && [ ! -h /opt/farm/ext/repos/lists/$OSVER ]; then
	echo "error: something is wrong with operating system version, aborting install"
	exit 1
fi

if [ "`resolve_host $HOST`" = "" ]; then
	HOST=`hostname`
	echo "warning: given hostname $1 has invalid format, continuing with the current server hostname $HOST"
else
	cp -a /etc/hostname /etc/hostname.orig
	/opt/farm/ext/system/set-hostname.sh $HOST
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

/opt/farm/scripts/setup/groups.sh
/opt/farm/setup.sh

/sbin/ifconfig -a |mail -s "Cloud instance $HOST setup finished" $SF_CONFIRM
