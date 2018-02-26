#!/bin/sh
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.dialog


mkdir -p   /var/log/provisioning /etc/local/.provisioning
chmod 0700 /var/log/provisioning /etc/local/.provisioning

ln -sf /opt/farm/ext/farm-provisioning/provision.sh /usr/local/bin/sf-provision

/opt/farm/ext/farm-provisioning/add-profile.sh default
