#!/bin/bash

# Clone Git Repository
git clone $GIT_URL /data/myapp

# Copy ECR Config to Kaniko
cp /config.json /docker/config.json

# Exit Cleanly
exit 0