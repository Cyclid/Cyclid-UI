#!/usr/bin/env bash

# Reconfigure Cyclid
sed -i -e "s#SERVER_URL#${SERVER_URL}#" /etc/cyclid/config
sed -i -e "s#CLIENT_URL#${CLIENT_URL}#" /etc/cyclid/config

# Start Cyclid under Unicorn
unicorn -E production -c /var/lib/cyclid-ui/unicorn.rb
