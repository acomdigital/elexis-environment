#!/bin/bash

# parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -ni|--non-interactive)
    NON_INTERACTIVE=true
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#
# ASSERT ENVIRONMENT-VARIABLES
#
NOW=$(date +%s)
cp -p /installdir/.env /installdir/.env.bkup.$NOW
mv /installdir/.env /installdir/.env.bkup
java -jar /EnvSubst.jar -s /installdir/.env.bkup -t /installdir/.env.template -f /installdir/.env ${NON_INTERACTIVE:+-a NoNoNoNo}

#
# REPLACING UUID TEMPLATE VARIABLES
# we need a new line for every replaced value in order to re-init a unique id
#
sed -i -e "0,/=missing-uuid/{s//=$(uuidgen)/}" /installdir/.env
sed -i -e "0,/=missing-uuid/{s//=$(uuidgen)/}" /installdir/.env

#
# TEST PRECONDITIONS
#
echo "=== Testing environment variables"

bats /stage_configure/tests.bats
if [ $? -ne 0 ]
then
  echo "Tests showed an error, not performing configuration"
  exit -1
fi

#
# PERFORM CONFIGURATION
#
echo "=== Preparing configuration files"

if [ ! -f "/site/dhparam.pem" ]; 
then
    echo "* generating dhparam.pem ... please wait ..."
    openssl dhparam -dsaparam -out /site/dhparam.pem 4096
else
    echo "  skipping dhparam.pem generation"
fi

if [ ! -f "/site/certificate.cnf" ]; 
then
echo "* writing ssl configuration file ..."
cat <<EOF >/site/certificate.cnf
# see https://www.switch.ch/pki/manage/request/csr-openssl/
FQDN=${EE_HOSTNAME}
ORGNAME=${ORGANISATION_NAME//__/ }
ALTNAMES = DNS:\$FQDN
[ req ]
default_bits = 2048
default_md = sha256
prompt = no
encrypt_key = no
distinguished_name = dn
req_extensions = req_ext
[ dn ]
C = CH
O = \$ORGNAME
CN = \$FQDN
[ req_ext ]
subjectAltName = \$ALTNAMES
EOF
else
  echo "  skipping certificate.cnf generation"
fi

if [ ! -f "/site/certificate.key" ]; 
then
    echo "* generating certificate.key/csr"
    openssl req -new -config /site/certificate.cnf -keyout /site/certificate.key -out /site/certificate.csr
else
    echo "  skipping certificate.key/csr generation"
fi
