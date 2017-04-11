#!/bin/bash

# cyclid-ui
docker run  --detach \
            -p 8080:80/tcp \
            --name cyclid-ui \
            --link cyclid-server:cyclid-server \
            cyclid/ui
