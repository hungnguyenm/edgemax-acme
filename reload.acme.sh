#!/bin/sh

mkdir -p /config/ssl
cat /tmp/key.pem /tmp/cert.pem > /config/ssl/server.pem
cp /tmp/fullchain.pem /config/ssl/ca.pem
rm /tmp/key.pem /tmp/cert.pem /tmp/fullchain.pem
