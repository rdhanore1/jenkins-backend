#!/bin/bash
dnf update -y
dnf install -y git python3 python3-pip

cd /opt
git clone https://github.com/rdhanore1/jenkins-backend.git

cd jenkins-backend
pip3 install -r requirements.txt

cat <<EOF > /etc/systemd/system/backend.service
[Unit]
Description=Flask Backend
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/jenkins-backend/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable backend
systemctl start backend
