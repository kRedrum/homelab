#!/bin/bash

HOST="<HOST>"
DOMAIN="<DOMAIN>"  
PASSWORD="<DDNS-PASSWORD>"  

CURRENT_IP=$(curl -s https://api64.ipify.org)
UPDATE_URL="https://dynamicdns.park-your-domain.com/update?host=$HOST&domain=$DOMAIN&password=$PASSWORD&ip=$CURRENT_IP"

RESPONSE=$(curl -s "$UPDATE_URL")

# Log the response
echo "$(date): $RESPONSE" >> /var/log/namecheap_ddns.log