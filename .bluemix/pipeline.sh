#!/bin/bash
echo hello world
export IBP_NAME="ibm-blockchain-5-dev"
export IBP_PLAN="ibm-blockchain-plan-v1-starter-dev"
export VCAP_KEY_NAME="Credentials-1"

#      export IBP_NAME="Blockchain"
#export IBP_PLAN="ibm-blockchain-plan-v1-ga1-dev"
#     export SERVICE_INSTANCE_NAME="Blockchain-i9"
# export VCAP_KEY_NAME="Credentials-1"

#printf "\n ----- admin-prive.pem ---- \n"
#    echo -----BEGIN PRIVATE KEY-----  > admin-priv.pem
#echo MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgktxsS/ykOJ3ssvB9 >> admin-priv.pem
#echo /RO8cPZRhoYE4Pv7k/SN03uX8ByhRANCAAR4/Edc4XsoqlLDMTXrwxHmUx6CUIY8 >> admin-priv.pem
#echo QIGrkqNxcz21QZZ1sYq/YdtjnYcBqo7gv1Y2ui1kdsHr4Ia26bTf6A7l >> admin-priv.pem
#echo -----END PRIVATE KEY----- >> admin-priv.pem
#     cat admin-priv.pem

#printf "\n ----- admin-pub.pem ---- \n"
#echo -----BEGIN CERTIFICATE----- > admin-public.pem
#echo MIIBjTCCATOgAwIBAgIUIkltg0/UgO0K9MVMEPwouxaSQoowCgYIKoZIzj0EAwIw >> admin-public.pem
#echo GzEZMBcGA1UEAxMQYWRtaW5QZWVyT3JnMkNBMTAeFw0xODAxMjUxMTE0MDBaFw0x >> admin-public.pem
#echo OTAxMjUxMTE0MDBaMBAxDjAMBgNVBAMTBWFkbWluMFkwEwYHKoZIzj0CAQYIKoZI >> admin-public.pem
#echo zj0DAQcDQgAEePxHXOF7KKpSwzE168MR5lMeglCGPECBq5KjcXM9tUGWdbGKv2Hb >> admin-public.pem
#echo Y52HAaqO4L9WNrotZHbB6+CGtum03+gO5aNgMF4wDgYDVR0PAQH/BAQDAgeAMAwG >> admin-public.pem
#echo A1UdEwEB/wQCMAAwHQYDVR0OBBYEFItz9w2Ssmo8blfHOjgsZJV5AzVEMB8GA1Ud >> admin-public.pem
#echo IwQYMBaAFELuOBpdQ+BTMwWRZdwJrZD0rQHyMAoGCCqGSM49BAMCA0gAMEUCIQDq >> admin-public.pem
#echo h/dWzJkA4vPEaEGpE4iG1V6XAvIbx31H3wSHC2QsGwIgLRyk3m23OPCE0uAV2ULO >> admin-public.pem
#echo QCvS6JZtxj4eGMBZ/ioQxmg= >> admin-public.pem
#echo -----END CERTIFICATE----- >> admin-public.pem
# cat admin-public.pem

# Test Code
printf "\n --- Listing services for testing ---\n"
cf services
#cf services | sed -n 's/.*\(ibm-blockchain-plan-v1-prod\).*/\1/p'
#cf services | sed -n 's/.*\(${SERVICE_INSTANCE_NAME}\).*/\1/p'

printf "\n ---- Install node and nvm ----- \n"
npm config delete prefix
     curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
     export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
nvm use node

    node -v

# -----------------------------------------------------------
# Detect if there is already a service we should use - [ Optional ]
# -----------------------------------------------------------
  printf "\n --- Detecting service options ---\n"
  if [ "$SERVICE_INSTANCE_NAME" != "" ]; then
    echo "A service instance name was provided, lets use that"
  else
    echo "A service instance name was NOT provided, lets use the default one"
    export SERVICE_INSTANCE_NAME="Blockchain-${CF_APP}"
  fi
    printf "Using service instance name '${SERVICE_INSTANCE_NAME}'\n"

# -----------------------------------------------------------
# Detect if we we have a callback url to hit when demo is alive - [ Optional ]
# -----------------------------------------------------------
  if [ "$ALIVE_SIGNAL" != "" ]; then
    echo "The alive signal url was provided, ${ALIVE_SIGNAL}"
    #export ALIVE_SIGNAL=`echo $ALIVE_SIGNAL | sed -r 's/%3A/:/g'
    curl -s --head $ALIVE_SIGNAL | head -n 1 | grep "HTTP/1.[01] [23].."
  fi

# -----------------------------------------------------------
# 1. Test if everything we need is set
# -----------------------------------------------------------
  printf "\n --- Testing if the script has what it needs ---\n"
  export SCRIPT_ERROR="nope"
  if [ "$IBP_NAME" == "" ]; then
    echo "Error - bad script setup - IBP_NAME was not provided (IBM Blockchain service name)"
    export SCRIPT_ERROR="yep"
  fi

  if [ "$IBP_PLAN" == "" ]; then
    echo "Error - bad script setup - IBP_PLAN was not provided (IBM Blockchain service's plan name)"
    export SCRIPT_ERROR="yep"
  fi

  if [ "$VCAP_KEY_NAME" == "" ]; then
    echo "Error - bad script setup - VCAP_KEY_NAME was not provided (Bluemix service credential key name)"
    export SCRIPT_ERROR="yep"
  fi

  if [ "$SERVICE_INSTANCE_NAME" == "" ]; then
    echo "Error - bad script setup - SERVICE_INSTANCE_NAME was not provided (IBM Blockchain service instance name)"
    export SCRIPT_ERROR="yep"
  fi

  if [ "$CF_APP" == "" ]; then
    echo "Error - bad script setup - CF_APP was not provided (Marbles application name)"
    export SCRIPT_ERROR="yep"
  fi

  if [ "$SCRIPT_ERROR" == "yep" ]; then
    exit 1
  else
    echo "All good"
  fi

# -----------------------------------------------------------
# 2. Create a service instance (this is okay to run if the service name already exists as long as its the same typeof service)
# -----------------------------------------------------------
  printf "\n --- Creating an instance of the IBM Blockchain Platform service ---\n"
  cf create-service ${IBP_NAME} ${IBP_PLAN} ${SERVICE_INSTANCE_NAME}
  cf create-service-key ${SERVICE_INSTANCE_NAME} ${VCAP_KEY_NAME} -c '{"msp_id":"PeerOrg1"}'

# -----------------------------------------------------------
# 3. Get service credentials into our file system (remove the first two lines from cf service-key output)
# -----------------------------------------------------------
  printf "\n --- Getting service credentials ---\n"
  cf service-key ${SERVICE_INSTANCE_NAME} ${VCAP_KEY_NAME} > ./config/temp.txt
  tail -n +2 ./config/temp.txt > ./config/vehicle_tc.json
  printf "\n --- testing temp.txt --- \n"
  cat ./config/temp.txt -b

  curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
  chmod +x jq
  export PATH=$PATH:$PWD

  jq --raw-output '.credentials[0].channels.defaultchannel.chaincodes = [] | .credentials[0]' ./config/vehicle_tc.json > ./config/connection-profile.json

  printf "\n --- testing vehicle_tc.json --- \n"
  cat ./config/connection-profile.json

  # npm install -g connection-profile-converter
  # connection-profile-converter --input ./config/vehicle_tc.json --output ./config/connection-profile.json --cf-service-key --name hlfv1

  # cp ./config/vehicle_tc.json ./config/connection-profile.json
  export SECRET=$(jq --raw-output 'limit(1;.certificateAuthorities[].registrar[0].enrollSecret)' ./config/connection-profile.json)
  printf "\n secret ${SECRET} \n"

  export NETWORKID=$(jq --raw-output '."x-networkId"' ./config/connection-profile.json)
  printf "\n networkid ${NETWORKID} \n"

  export USERID=$(jq --raw-output '."x-api".key' ./config/connection-profile.json)
  printf "\n userid ${USERID} \n"

  export PASSWORD=$(jq --raw-output '."x-api".secret' ./config/connection-profile.json)
  printf "\n password ${PASSWORD} \n"

  export API_URL=$(jq --raw-output '."x-api".url' ./config/connection-profile.json)
  printf "\n apiurl ${API_URL} \n"

  export MSPID=$(jq --raw-output 'limit(1; .organizations[].mspid)' ./config/connection-profile.json)
  printf "\n mspid ${MSPID} \n"

  export PEER=$(jq --raw-output 'limit(1; .organizations[].peers[0])' ./config/connection-profile.json)
  printf "\n peer ${PEER} \n"

  export CHANNEL="defaultchannel"



# -----------------------------------------------------------
# 4. Install composer-cli
# -----------------------------------------------------------
  printf "\n ---- Install composer-cli ----- \n "

  npm install -g composer-cli@next-unstable

  composer -v

  printf "\n ----- create ca card ----- \n"
  composer card create -f ca.card -p ./config/connection-profile.json -u admin -s ${SECRET}
  composer card import -f ca.card -n ca
  composer identity request --card ca --path ./credentials
  ls -la ./credentials

  export PUBLIC_CERT=$(cat ./credentials/admin-pub.pem)

  printf "\n public cert ${PUBLIC_CERT} \n"

# -----------------------------------------------------------
# 5. Add and sync admin cert
# -----------------------------------------------------------
  # add admin cert
  printf "\n ----- add certificate ----- \n"
  cat << EOF > request.json
{
"msp_id": "${MSPID}",
"peers": ["${PEER}"],
"adminCertName": "my cert",
"adminCertificate": "${PUBLIC_CERT}"
}
EOF

  cat request.json
  echo curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} --data-raw @request.json ${API_URL}/api/v1/networks/${NETWORKID}/certificates
       curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} --data-raw @request.json ${API_URL}/api/v1/networks/${NETWORKID}/certificates

  # sync certificates
  printf "\n ----- sync certificate ----- \n"
  echo curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/channels/$(CHANNEL}/sync
       curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/channels/${CHANNEL}/sync

  # stop peer
  printf "\n ----- stop peer ----- \n"
  echo curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/nodes/${PEER}/stop
       curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/nodes/${PEER}/stop

  # start peer
  printf "\n ----- start peer ----- \n"
  echo curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/nodes/${PEER}/start
       curl -X POST --header 'Content-Type: application/json --header 'Accept: application/json' --basic --user ${USERID}:${PASSWORD} -d '{}' ${API_URL}/api/v1/networks/${NETWORKID}/nodes/${PEER}/start

# -----------------------------------------------------------
# 6. Create new card
# -----------------------------------------------------------
  printf "\n ---- Create admin card ----- \n "
  composer card create -f adminCard.card -p ./config/connection-profile.json -u admin -c ./credentials/admin-pub.pem -k ./credentials/admin-priv.pem --role PeerAdmin --role ChannelAdmin

  composer card import -f adminCard.card -n adminCard

# -----------------------------------------------------------
# 7. Deploy the network
# -----------------------------------------------------------
  printf "\n --- get network --- \n"
  npm install vehicle-manufacture-network

  printf "\n --- create archive --- \n"
  composer archive create -a ./vehicle-manufacture-network.bna -t dir -n node_modules/vehicle-manufacture-network

  printf "\n --- install network --- \n"
  composer runtime install -c adminCard -n vehicle-manufacture-network

  printf "\n --- start network --- \n"
  composer network start -c adminCard -a vehicle-manufacture-network.bna -A admin -C admin-public.pem -f delete_me.card

  composer card delete -n admin@vehicle-manufacture-network

  composer card create -n vehicle-manufacture-network -p ./config/connection-profile.json -u admin -c admin-public.pem -k admin-priv.pem

  composer card import -f ./admin@vehicle-manufacture-network.card

# -----------------------------------------------------------
# 8. Install Composer Playground
# -----------------------------------------------------------
  printf "\n ---- Install composer-playground ----- \n"
  npm install composer-playground@next-unstable

  cd node_modules/composer-playground

  cf push composer-playground-${CF_APP} -c "node cli.js" -i 2 -m 128M --no-start
  cf set-env composer-playground-${CF_APP} COMPOSER_CONFIG '{"webonly":true}'
  cf start composer-playground-${CF_APP}

# -----------------------------------------------------------
# 9. Install Composer Rest Server
# -----------------------------------------------------------
  printf "\n----- Install REST server ----- \n"
  cd ../..
  npm install composer-rest-server@next-unstable
  cd node_modules/composer-rest-server
  cf push composer-rest-server-${CF_APP} -c "node cli.js -c admin@vehicle-manufacture-network -n always -w true" -i 2 -m 512M --no-start
  cf start composer-rest-server-${CF_APP}

# -----------------------------------------------------------
# 10. Start the app
# -----------------------------------------------------------

  # Push app (don't start yet, wait for binding)
  printf "\n --- Creating the Vehicle manufacture application '${CF_APP}' ---\n"
  cf push ${CF_APP} --no-start
  cf set-env ${CF_APP} REST_SERVER_CONFIG '{"webSocketURL": "ws://composer-rest-server-${CF_APP}", "httpURL": "composer-rest-server-${CF_APP}/api"}'

  # Bind app to the blockchain service
  printf "\n --- Binding the IBM Blockchain Platform service to Vehicle manufacture app ---\n"
  cf bind-service ${CF_APP} ${SERVICE_INSTANCE_NAME} -c "{\"permissions\":\"read-only\"}"

  # Start her up
  printf "\n --- Starting vehicle manufacture app '${CF_APP}' ---\n"
  cf start ${CF_APP}

# -----------------------------------------------------------
# 11. Ping IBP that the application is alive  - [ Optional ]
# -----------------------------------------------------------
  if [ "$ALIVE_SIGNAL" != "" ]; then
    printf "\n --- Sending signal that the demo is alive ---\n"
    curl -s --head $ALIVE_SIGNAL | head -n 1 | grep "HTTP/1.[01] [23].."
  fi

  printf "\n\n --- We are done here. ---\n\n"
