#!/bin/bash

for a in $(cat apps.txt); do curl -k -u 'admin:changeme' https://localhost:8089/services/apps/local/$a -d visible=false; done