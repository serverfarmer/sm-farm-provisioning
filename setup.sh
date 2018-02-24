#!/bin/sh
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.dialog


mkdir -p   /var/log/provisioning /etc/local/.provisioning/default
chmod 0700 /var/log/provisioning /etc/local/.provisioning

newrelic="/etc/local/.config/newrelic.license"
template="/etc/local/.provisioning/default/variables.sh"

if [ -f $template ]; then
	echo "provisioning configuration template already found, exiting"
	exit 0
fi


if [ -s $newrelic ]; then
	NEWRELIC_LICENSE="`cat $newrelic`"
else
	read -p "enter default newrelic.com license key for provisioning: " NEWRELIC_LICENSE
fi

stty -echo
read -p "enter default snmp v2 community for provisioning: " SNMP_COMMUNITY
stty echo
echo ""  # force a carriage return to be output

SMTP_RELAY="`input \"enter default smtp relay hostname for provisioning\" smtp.gmail.com`"
read -p "[$SMTP_RELAY] enter login: " SMTP_USERNAME
stty -echo
read -p "[$SMTP_RELAY] enter password for $SMTP_USERNAME: " SMTP_PASSWORD
stty echo
echo ""  # force a carriage return to be output


if [ "$NEWRELIC_LICENSE" = "" ]; then
	NEWRELIC_LICENSE="put-your-newrelic-license-key-here"
fi
if [ "$SNMP_COMMUNITY" = "" ]; then
	SNMP_COMMUNITY="put-your-snmp-community-here"
fi
if [ "$SMTP_USERNAME" = "" ]; then
	SMTP_USERNAME="my-user@gmail.com"
fi
if [ "$SMTP_PASSWORD" = "" ]; then
	SMTP_PASSWORD="my-password"
fi


echo "#!/bin/sh
#
# Settings to use in unattended setup mode; please fill in all variables.
#
# extensions part:
#
export NEWRELIC_LICENSE=$NEWRELIC_LICENSE
export SNMP_COMMUNITY=$SNMP_COMMUNITY
#
# core SF part:
#
export SMTP_RELAY=$SMTP_RELAY
export SMTP_USERNAME=$SMTP_USERNAME
export SMTP_PASSWORD=$SMTP_PASSWORD
#
# Github username (or organization short name), where you have forked
# Server Farmer main repository.
#
export SF_GITHUB=`grep github.com /opt/farm/.git/config |rev |cut -d'/' -f2 |rev`
#
# Email address for confirmations about successful setups.
#
export SF_CONFIRM=serverfarmer-provisioning@`external_domain`
" >$template
chmod 0700 $template

ln -sf /opt/farm/ext/farm-provisioning/provision.sh /usr/local/bin/sf-provision
