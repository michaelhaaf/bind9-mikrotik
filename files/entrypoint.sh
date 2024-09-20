#!/bin/sh
mkdir -p /var/named
cp -R etc /
cp -R var /

chown -R named /var/named
chown -R bind:bind /etc/bind/
chown -R bind:bind /var/lib/bind/

named -c /etc/bind/named.conf -g -u named
