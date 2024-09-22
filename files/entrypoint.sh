#!/bin/sh

mkdir -p /var/cache/bind
chown -R named:named /etc/bind/
chown -R named:named /var/lib/bind/
chown -R named:named /var/cache/bind/

named -c /etc/bind/named.conf -g -u named && \
	dhcpd -4 -f -d --no-pid -cf /etc/dhcp/dhcpd.conf || \
	tail -f /dev/null
