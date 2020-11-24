#!/bin/bash

set -xeo pipefail

# Install additional CA certificates to shared PKI store for Chrome (e.g. for development)
mkdir -p ~/ca/
shopt -s nullglob

if [ -n "$CA_CERT" ]; then
 echo "$CA_CERT" > ~/ca/"${CA_CERT_NAME:-'environment'}".crt
fi

mkdir -p $HOME/.pki/nssdb
certutil -d $HOME/.pki/nssdb -N --empty-password
for CAcert in ~/ca/*.crt; do
 filename=$(basename $CAcert)
 certutil -A -n "${filename%.*}" -t "TCu,Cuw,Tuw" -i ${CAcert} -d sql:$HOME/.pki/nssdb
done

# Create a new Chrome profile
mkdir -p /tmp/chrome-profile

# Start Chrome browser and point it at the URL we want to capture
exec google-chrome \
  --window-size=${SCREEN_WIDTH},${SCREEN_HEIGHT} \
  --no-sandbox \
  --disable-sync \
  --no-first-run \
  --user-data-dir=/tmp/chrome-profile \
  --kiosk "${MEETING_URL}"
