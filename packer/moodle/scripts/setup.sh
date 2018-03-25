#!/bin/bash

echo Setting up Nginx, Vault and PHP-FPM...
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini
apt-get install -y nginx jq
systemctl reload nginx
chmod a+w /etc/nginx/sites-available/default