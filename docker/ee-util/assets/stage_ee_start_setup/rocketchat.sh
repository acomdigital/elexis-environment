#!/bin/bash
#
# Configure Rocket.Chat for Elexis Operation
#
RC_BASEURL="http://rocketchat:3000/chat"
T="[ROCKETCHAT] "
echo "$T ===================================================="

#
#
# Wait for login
#
#
echo "$T Log-in as RocketChatAdmin..."
RESPONSE=$(curl -s -k $RC_BASEURL/api/v1/login -d "user=RocketChatAdmin&password=$ADMIN_PASSWORD") 
STATUS="$?"
LOOP_COUNT=0
while [ $STATUS != 0 ] 
do 
    echo "$T Waiting for rocketchat [$STATUS] ($RESPONSE) ..."
    sleep 15
    RESPONSE=$(curl -s -k $RC_BASEURL/api/v1/login -d "user=RocketChatAdmin&password=$ADMIN_PASSWORD") 
    STATUS="$?"
    (( LOOP_COUNT += 1 ))
    if [ $LOOP_COUNT -eq 20 ]; then exit -1; fi
done

AUTH_TOKEN=$(echo $RESPONSE | jq -r .data.authToken)
USER_ID=$(echo $RESPONSE | jq -r .data.me._id)

#
#
# Assert Styling
#
#
echo "$T Assert asset.background image ... "
# https://rocket.chat/docs/developer-guides/rest-api/assets/setasset/
curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -F "background=@rocketchat/Login-screen.png" $RC_BASEURL/api/v1/assets.setAsset 
echo "\n"

#
#
# Basic configuration values
#
#
java -jar /RocketchatSetting.jar -l RocketChatAdmin -p $ADMIN_PASSWORD -u $RC_BASEURL -v \
    -s Accounts_PasswordReset=false -s Accounts_RegistrationForm=Disabled -s Accounts_RegistrationForm_LinkReplacementText="" \
    -s API_Enable_Rate_Limiter_Limit_CallsDefault=100 -s Site_Name=$ORGANISATION_NAME -s Organization_Name=$ORGANISATION_NAME

#
#
# Assert Keycloak SAML Integration
#
#
echo "$T Assert Keycloak SAML integration ... "
REALM_CERT=$(jq '.keys[] | select(.algorithm == "RS256") | select(.status == "ACTIVE") | .certificate' -r /ElexisEnvironmentRealmKeys.json)
java -jar /RocketchatSetting.jar -l RocketChatAdmin -p $ADMIN_PASSWORD -u $RC_BASEURL -v \
    -s SAML_Custom_Default=true -s SAML_Custom_Default_provider=rocketchat-saml \
    -s SAML_Custom_Default_entry_point=https://$EE_HOSTNAME/keycloak/auth/realms/ElexisEnvironment/protocol/saml \
    -s SAML_Custom_Default_idp_slo_redirect_url=/keycloak/auth/realms/ElexisEnvironment/protocol/saml \
    -s SAML_Custom_Default_issuer=rocketchat-saml -s SAML_Custom_Default_button_label_text=Elexis-Environment \
    -s SAML_Custom_Default_cert=$REALM_CERT -s SAML_Custom_Default_logout_behaviour=Local

#
#
# Assert Elexis-Server Webhook/Channel Integration
#
#
echo -e "\n$T Assert Elexis-Server - channel #elexis-server ..."
curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -H "Content-type: application/json" $RC_BASEURL/api/v1/channels.create -d '{ "name": "elexis-server", "description": "Elexis-Server status messages" }'

echo -e "\n$T Assert Elexis-Server - bot user for elexis-user ..."
curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -H "Content-type: application/json" $RC_BASEURL/api/v1/users.create --data-binary @rocketchat/cr_es_user.json

echo -e "\n$T Assert Elexis-Server - bot avatar for elexis-server ..."
curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -F "image=@rocketchat/elexis-server.png" -F "username=elexis-server" $RC_BASEURL/api/v1/users.setAvatar 

echo -e "\n$T Assert Elexis-Server - webhook integration for elexis-server..."
EX_INTEGRATIONS=$(curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -H "Content-type: application/json" $RC_BASEURL/api/v1/integrations.list)
EXISTING=$(echo $EX_INTEGRATIONS | jq '.integrations[] | select(.name=="elexis-server-messages")')
if [ -z "$EXISTING" ]
then
    echo "Creating webhook ..."
    EXISTING=$(curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" -H "Content-type: application/json" $RC_BASEURL/api/v1/integrations.create --data-binary @rocketchat/cr_es_inc_webhook.json)
fi
echo $EXISTING

echo "$T Log-Out as RocketChatAdmin..."
curl -s -k -H "X-Auth-Token: $AUTH_TOKEN" -H "X-User-Id: $USER_ID" $RC_BASEURL/api/v1/logout

TOKEN=$(echo $EXISTING | jq -r .token)
ID=$(echo $EXISTING | jq -r ._id)
LASTUPDATE=$(date +%s)000
MYSQL_STRING="INSERT INTO CONFIG(lastupdate, param, wert) VALUES ('${LASTUPDATE}','EE_RC_ES_INTEGRATION_WEBHOOK_TOKEN', '${ID}/${TOKEN}') ON DUPLICATE KEY UPDATE wert = '${ID}/${TOKEN}', lastupdate='${LASTUPDATE}'"
/usql mysql://${RDBMS_ELEXIS_USERNAME}:${RDBMS_ELEXIS_PASSWORD}@${RDBMS_HOST}:${RDBMS_PORT}/${RDBMS_ELEXIS_DATABASE} -c "$MYSQL_STRING"
