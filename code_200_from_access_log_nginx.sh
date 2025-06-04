#!/bin/bash
cat /var/log/nginx/access.log | awk '{print $9}' | grep -c 200
exit 0
