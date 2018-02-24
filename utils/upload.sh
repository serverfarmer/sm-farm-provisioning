#!/bin/sh
. /opt/farm/scripts/functions.custom

target=$1
tmpkey=$2
profile=$3
mode=$4

if [ "$mode" = "ec2" ] || [ "$mode" = "gce" ]; then
	firstuser="ubuntu"
else
	firstuser="root"
fi

ssh -i $tmpkey -o StrictHostKeyChecking=no -o PasswordAuthentication=no $firstuser@$target uptime >/dev/null 2>/dev/null

if [[ $? != 0 ]]; then
	echo "error: host $target denied access"
	exit 1
fi

log=/var/log/provisioning/$target.log
echo "### BEGIN `date +'%Y-%m-%d %H:%M:%S'` ###" >>$log

# initial key is set only for ubuntu user - set it up also for root
if [ "$mode" = "ec2" ] || [ "$mode" = "gce" ]; then
	ssh -i $tmpkey $firstuser@$target "cat /home/$firstuser/.ssh/authorized_keys |sudo tee /root/.ssh/authorized_keys >/dev/null" >>$log
fi

# copy setup scripts to provisioned host
scp -i $tmpkey /etc/local/.provisioning/$profile/variables.sh /opt/farm/ext/farm-provisioning/resources/setup-server-farmer.sh root@$target:/root >>$log

# install Server Farmer
if [ "$mode" = "gce" ]; then
	ssh -i $tmpkey root@$target /bin/rm -f /etc/apt/sources.list.d/partner.list >>$log 2>>$log
	ssh -i $tmpkey root@$target /root/setup-server-farmer.sh - >>$log 2>>$log
else
	ssh -i $tmpkey root@$target /root/setup-server-farmer.sh $target >>$log 2>>$log
fi

echo "### END `date +'%Y-%m-%d %H:%M:%S'` ###" >>$log
