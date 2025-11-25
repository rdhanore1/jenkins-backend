#!/bin/bash
dnf update -y
dnf install -y git nodejs npm

cd /opt
git clone https://github.com/rdhanore1/jenkins-frontend.git

cd jenkins-frontend
npm install

cat <<EOF > /etc/systemd/system/frontend.service
[Unit]
Description=Express Frontend
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/jenkins-frontend/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable frontend
systemctl start frontend
