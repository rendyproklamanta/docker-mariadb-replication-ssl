#!/bin/bash

## THIS WILL GENERATE SSL FOR USE IN LOCAL DEVELOPMENT ONLY
## SSL ONLY VALID FOR 4 HOURS, AND IT WILL RE-GENERATE
## SAFE NEW GENERATED SSL TO GITLAB SNIPPET

# Generate the CA certificate
sudo openssl genrsa 2048 > ca-key.pem
sudo openssl req -new -x509 -nodes -days 0 -hours 4 -key ca-key.pem -out ca-cert.pem -subj "/CN=mariadb_CA"

# Generate the server key and certificate
sudo openssl req -newkey rsa:2048 -days 0 -hours 4 -nodes -keyout server-key.pem -out server-req.pem -subj "/CN=mariadb_server"
sudo openssl rsa -in server-key.pem -out server-key.pem
sudo openssl x509 -req -in server-req.pem -days 0 -hours 4 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# Generate the client key and certificate
sudo openssl req -newkey rsa:2048 -days 0 -hours 4 -nodes -keyout client-key.pem -out client-req.pem -subj "/CN=mariadb_client"
sudo openssl rsa -in client-key.pem -out client-key.pem
sudo openssl x509 -req -in client-req.pem -days 0 -hours 4 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

# Generate the MaxScale key and certificate
sudo openssl req -newkey rsa:2048 -days 0 -hours 4 -nodes -keyout maxscale-key.pem -out maxscale-req.pem -subj "/CN=mariadb_maxscale"
sudo openssl rsa -in maxscale-key.pem -out maxscale-key.pem
sudo openssl x509 -req -in maxscale-req.pem -days 0 -hours 4 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out maxscale-cert.pem

# Remove request
rm -rf *-req.pem

## -----------------------------------
## Safe certs to gitlab snippet
## -----------------------------------

# Variables
GITLAB_TOKEN=''
GITLAB_PROJECT_ID=''
GITLAB_SNIPPET_TITLE=''
GITLAB_API_URL=''
GITLAB_API_ENDPOINT="${GITLAB_API_URL}/api/v4/projects/$GITLAB_PROJECT_ID/snippets"

# Fetch existing snippets and delete the one with the matching title
EXISTING_SNIPPET_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_ENDPOINT" | jq --arg title "$GITLAB_SNIPPET_TITLE" '.[] | select(.title == $title) | .id')

if [ -n "$EXISTING_SNIPPET_ID" ]; then
  echo "**** Delete existing snippet ID: $EXISTING_SNIPPET_ID ****"
  echo ""
  curl --silent --request DELETE "$GITLAB_API_URL/$EXISTING_SNIPPET_ID" --header "PRIVATE-TOKEN: $GITLAB_TOKEN"
fi

RESPONSE=curl --silent --request POST "$GITLAB_API_ENDPOINT" \
   --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
   --form "title=$GITLAB_SNIPPET_TITLE" \
   --form "visibility=private" \
   --form "files[0][file_name]=ca-cert.pem" \
   --form "files[0][content]=$(<ca-cert.pem)" \
   --form "files[1][file_name]=client-key.pem" \
   --form "files[1][content]=$(<client-key.pem)" \
   --form "files[2][file_name]=client-cert.pem" \
   --form "files[2][content]=$(<client-cert.pem)"

# Check for errors in the response
ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')

if [ -n "$ERROR_MESSAGE" ]; then
  echo "Error: $ERROR_MESSAGE"
  exit 1
fi

echo "**** Rolling certs successfuly ****"
echo ""

# Optionally, log to a file (ensure this file is secured)
echo -e "$CONTENT" > /var/log/db_certs.log