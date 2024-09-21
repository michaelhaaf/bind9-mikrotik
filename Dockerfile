FROM alpine:latest

MAINTAINER michaelhaaf <michael.haaf@gmail.com>

COPY files/entrypoint.sh .
COPY files/etc /etc
COPY files/var /var

RUN apk update
RUN apk add bind bind-dnssec-tools dhcp-server-vanilla

RUN addgroup -S bind && adduser -S bind -G bind
RUN chown -R bind:bind /etc/bind/
RUN chown -R bind:bind /var/lib/bind/
RUN chmod +x entrypoint.sh

EXPOSE 53

CMD ["/entrypoint.sh"]
