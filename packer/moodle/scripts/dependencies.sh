#!/bin/bash

echo Install dependencies...
apt-get -y update
apt-get -y upgrade

apt install -y php-cli php-fpm php-zip php-xml php-mbstring php-mcrypt php-curl php-gd php-pgsql php-bz2 php-gettext php-pear php-phpseclib php-tcpdf php-intl
