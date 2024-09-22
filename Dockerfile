FROM alpine:latest

MAINTAINER michaelhaaf <michael.haaf@gmail.com>

COPY files/entrypoint.sh /usr/local/bin/
COPY files/etc /etc
COPY files/var /var

RUN apk update
RUN apk add bind bind-dnssec-tools dhcp-server-vanilla

RUN addgroup -S bind && adduser -S bind -G bind
RUN mkdir -p /var/cache/bind
RUN chown -R named:named /etc/bind/
RUN chown -R named:named /var/lib/bind/
RUN chown -R named:named /var/cache/bind/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 53

CMD ["/usr/local/bin/entrypoint.sh"]
