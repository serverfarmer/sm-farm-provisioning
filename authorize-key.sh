#!/bin/bash
. /opt/farm/ext/net-utils/functions

if [ "$3" = "" ]; then
	echo "usage: $0 <hostname[:port]> <username> <ssh-key-path>"
	exit 1
elif [ "`resolve_host $1`" = "" ]; then
	echo "error: parameter $1 not conforming hostname format, or given hostname is invalid"
	exit 1
elif ! [[ $2 =~ ^[a-z0-9._-]+$ ]]; then
	echo "error: parameter $2 not conforming username format"
	exit 1
elif [ ! -f $3 ] || [ ! -f $3.pub ]; then
	echo "error: key $3 not found (both private and public keys are required)"
	exit 1
fi

server=$1
user=$2
newkey=$3
keytext="`head -n1 $newkey.pub`"

if [ -z "${server##*:*}" ]; then
	host="${server%:*}"
	port="${server##*:}"
else
	host=$server
	port=22
fi

ssh -p $port -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -o PasswordAuthentication=yes $user@$host \
	"mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; echo \"$keytext\" >> ~/.ssh/authorized_keys"

if [[ $? != 0 ]]; then
	echo "error: host $host denied access (wrong password for $user@$host?)"
	exit 1
fi
