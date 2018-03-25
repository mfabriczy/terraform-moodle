#!/bin/bash

echo Downloading and preparing Moodle...
git clone -b master --single-branch https://github.com/moodle/moodle.git
mkdir -p /usr/share/nginx/moodledata
chmod 777 /usr/share/nginx/moodledata
mv moodle /usr/share/nginx/html
chmod a+w /usr/share/nginx/html/moodle
