FROM alpine:latest

MAINTAINER michaelhaaf <michael.haaf@gmail.com>

RUN apk update
RUN apk add bind bind-dnssec-tools dhcp-server-vanilla

COPY files/entrypoint.sh /usr/local/bin/
COPY files/etc /etc
COPY files/var /var

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 53

CMD ["/usr/local/bin/entrypoint.sh"]
