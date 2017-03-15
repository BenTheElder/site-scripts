#!/bin/bash
# GCE bootstrap script
# run as root to setup project
set -v

# default to a service comment
CADDY_ENV="${CADDY_ENV:-;}"
# empty string or -email=<email>
if [ -z "${CADDY_EMAIL}" ]; then
    CADDY_EMAIL_ARG=""
else
    CADDY_EMAIL_ARG="-email=${CADDY_EMAIL}"
fi

# fetch olivaw
cd /homw/olivaw/olivaw
git pull
cd /home/olivaw
chown -R olivaw:olivaw /home/olivaw
chown -R olivaw:olivaw /home/olivaw/.[!.]*

# install dependencies
apt-get update
apt-get install -yq \
    git build-essential supervisor python python-dev python-pip libffi-dev \
    libssl-dev virtualenv

# setup python
pip install --upgrade pip virtualenv

# install app dependencies
virtualenv /home/olivaw/env
/home/olivaw/env/bin/pip install -r /home/olivaw/requirements.txt

# install caddy
wget -O caddy_linux_amd_custom.tar.gz "https://caddyserver.com/download/build?os=linux&arch=amd64&features=git%2Ccloudflare"
systemctl stop caddy
tar xf caddy_linux_amd_custom.tar.gz
mv ./caddy /usr/local/bin/caddy
setcap cap_net_bind_service=+ep /usr/local/bin/caddy
mkdir /etc/caddy
chown -R root:olivaw /etc/caddy
mkdir /etc/ssl/caddy
chown -R olivaw:root /etc/ssl/caddy
chmod 0770 /etc/ssl/caddy
mkdir /home/olivaw/www

# make sure olivaw owns the application
chown -R olivaw:olivaw /home/olivaw


# add service for olivaw
cat >/etc/systemd/system/olivaw.service << EOF
[Unit]
Description=Gunicorn instance to serve olivaw
After=network.target

[Service]
User=olivaw
Group=olivaw
WorkingDirectory=/home/olivaw
Environment=VIRTUAL_ENV=/home/olivaw/env/olivaw
Environment=PATH=/home/olivaw/env/bin
Environment=SECRETS_PATH=/home/olivaw/secrets.cfg
ExecStart=/home/olivaw/env/bin/gunicorn olivaw.main:app --bind 0.0.0.0:8080

[Install]
WantedBy=multi-user.target
EOF

# add service for caddy
# derived from
# https://github.com/mholt/caddy/blob/master/dist/init/linux-systemd/caddy.service
cat >/etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=always
StartLimitInterval=86400
StartLimitBurst=5

; User and group the process will run as.
User=olivaw
Group=olivaw

; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/etc/ssl/caddy
; site specific environment variables
$CADDY_ENV

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/local/bin/caddy -log stdout -agree=true -conf=/home/olivaw/site-scripts/gcp/Caddyfile -root=/var/tmp $CADDY_EMAIL_ARG
ExecReload=/bin/kill -USR1 $MAINPID

; Limit the number of file descriptors; see \`man systemd.exec\` for more limit settings.
LimitNOFILE=1048576
; Unmodified caddy is not expected to use more than that.
LimitNPROC=64

; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
; Use a minimal /dev
PrivateDevices=true
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
;ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
;ProtectSystem=full
; except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
; This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWriteDirectories=/etc/ssl/caddy
ReadWriteDirectories=/home/olivaw

; The following additional security directives only work with systemd v229 or later.
; They further retrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# start services
systemctl daemon-reload
systemctl start caddy.service
systemctl enable caddy.service
systemctl start olivaw.service
systemctl enable olivaw.service
