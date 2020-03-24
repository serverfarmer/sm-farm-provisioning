#!/bin/sh

/opt/farm/scripts/setup/extension.sh sf-net-utils

mkdir -p   /var/log/provisioning /etc/local/.provisioning
chmod 0700 /var/log/provisioning /etc/local/.provisioning

/opt/farm/mgr/farm-provisioning/add-profile.sh default
