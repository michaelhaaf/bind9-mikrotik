#!/bin/sh

named -c /etc/bind/named.conf -g -u named || tail -f /dev/null
