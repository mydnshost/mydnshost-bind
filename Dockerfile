# FROM alpine:latest
FROM internetsystemsconsortium/bind9:9.16

MAINTAINER Shane Mc Cormack <shanemcc@gmail.com>

# RUN set -x \
#     && apk add --no-cache bash bind \
#     && rm -rf /var/cache/apk/*

EXPOSE 53
EXPOSE 53/udp

COPY mydnshost-entrypoint.sh /
COPY bind /etc/bind

RUN set -x \
    && mkdir /bind \
    && mkdir /etc/bind/data \
    && mkdir /bind/keys \
    && ln -s /bind/keys /etc/bind/keys \
    && chmod +x /mydnshost-entrypoint.sh

ENTRYPOINT [ "/mydnshost-entrypoint.sh" ]
CMD [""]
