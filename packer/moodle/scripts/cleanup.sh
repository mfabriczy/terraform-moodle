#!/bin/bash

echo Cleanup...
chmod 644 /etc/nginx/sites-available/default
chmod 755 /usr/share/nginx/html/moodle

apt-get -y autoremove
apt-get -y clean

rm -rf /tmp/*
rm -rf /ops
