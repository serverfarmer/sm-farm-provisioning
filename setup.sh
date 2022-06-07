#!/bin/sh

/opt/farm/scripts/setup/extension.sh sf-net-utils

if [ "`whoami`" = "root" ]; then
	if [ -d /etc/local/.provisioning ] && [ ! -d ~/.serverfarmer/provisioning ]; then
		mv -f /etc/local/.provisioning ~/.serverfarmer/provisioning
	fi
	if [ -d /var/log/provisioning ] && [ ! -d ~/.serverfarmer/provisioning-logs ]; then
		mv -f /var/log/provisioning ~/.serverfarmer/provisioning-logs
	fi
fi

mkdir -p   ~/.serverfarmer/provisioning ~/.serverfarmer/provisioning-logs
chmod 0700 ~/.serverfarmer/provisioning ~/.serverfarmer/provisioning-logs

/opt/farm/mgr/farm-provisioning/add-profile.sh default
