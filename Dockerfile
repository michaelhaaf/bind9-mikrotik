FROM alpine:latest

MAINTAINER michaelhaaf <michael.haaf@gmail.com>

COPY files .

RUN apk update \
	&& apk add bind bind-dnssec-tools dhcp-server-vanilla \
	&& chmod +x entrypoint.sh

volume /var/named /etc/bind /var/lib/bind

EXPOSE 53

CMD ["/entrypoint.sh"]
