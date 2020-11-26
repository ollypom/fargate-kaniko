#!/bin/bash

# Copy ECR Config to Kaniko
cat <<EOF >>/kaniko/.docker/config.json
{ "credsStore": "ecr-login" }
EOF

while [ ! -f /data/ready ]
do
    echo "Not Ready to Start the Build"
    sleep 2
done

echo "Ready to Start the Build"
/busybox/sh /data/executer.sh