#!/bin/bash
# GCE startup script
set -v
export HOME=/root

# get project id
PROJECTID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")

# add user for application
useradd -m -d /home/olivaw olivaw

# fetch the source
rm -rf ./olivaw_tmp
git clone https://github.com/BenTheElder/site-scripts ./olivaw_tmp
mv ./olivaw_tmp/* ./olivaw_tmp/.* /home/olivaw/site-scripts
git clone https://github.com/BenTheElder/olivaw /home/olivaw/olivaw

# fetch olivaw
cd /home/olivaw
git clone https://github.com/BenTheElder/olivaw
chown -R olivaw:olivaw /home/olivaw
chown -R olivaw:olivaw /home/olivaw/.[!.]*

# run startup script
( "./site-scripts/gce/bootstrap.sh" )
