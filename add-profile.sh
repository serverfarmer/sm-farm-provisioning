#!/bin/sh
. /opt/farm/scripts/functions.dialog


if [ "$1" = "" ]; then
	echo "usage: $0 <profile>"
	exit 1
fi

template=~/.serverfarmer/provisioning/$1/variables.sh
fwconfig="/opt/farm/ext/firewall/.git/config"
domain=`/opt/farm/config/get-external-domain.sh`

if [ -f $template ]; then
	echo "provisioning configuration template \"$1\" already found, exiting"
	exit 0
fi


if [ -f $fwconfig ] && grep -q git@ $fwconfig; then
	giturl=`grep git@ $fwconfig |awk "{ print \\$3 }"`
else
	giturl="git@github.com:your/firewall.git"
fi

SNMP_COMMUNITY="`input \"enter snmp v2 community for provisioning\" put-your-snmp-community-here`"

SMTP_RELAY="`input \"enter default smtp relay hostname for provisioning\" smtp.gmail.com`"
SMTP_USERNAME="`input \"[$SMTP_RELAY] enter login\" my-user@gmail.com`"
SMTP_PASSWORD="`input \"[$SMTP_RELAY] enter password for $SMTP_USERNAME\" my-password`"

FW_REPOSITORY="`input \"enter firewall repository url\" $giturl`"
FW_SSH_KEY="`input \"[$FW_REPOSITORY] enter ssh key name\" id_github_firewall`"


mkdir -p ~/.serverfarmer/provisioning/$1
echo "#!/bin/sh
#
# Settings to use in unattended setup mode; please fill in all variables.
#
# extensions part:
#
export SNMP_COMMUNITY=$SNMP_COMMUNITY
#
# core SF part:
#
export SMTP_RELAY=$SMTP_RELAY
export SMTP_USERNAME=$SMTP_USERNAME
export SMTP_PASSWORD=$SMTP_PASSWORD
#
# firewall - optional private repository:
#
export FW_REPOSITORY=$FW_REPOSITORY
export FW_SSH_KEY=$FW_SSH_KEY
#
# Github username (or organization short name), where you have forked
# Server Farmer main repository.
#
export SF_GITHUB=`grep github.com /opt/farm/.git/config |rev |cut -d'/' -f2 |rev`
#
# Email address for confirmations about successful setups.
#
export SF_CONFIRM=serverfarmer-provisioning@$domain
" >$template
chmod 0600 $template
