FROM nguoianphu/docker-dns

MAINTAINER Shane Mc Cormack <shanemcc@gmail.com>

EXPOSE 53
EXPOSE 53/udp

COPY bind/* /etc/bind/
COPY mydnshost-entrypoint.sh /

RUN mkdir /bind && chmod +x /mydnshost-entrypoint.sh

ENTRYPOINT [ "/mydnshost-entrypoint.sh" ]
CMD [""]
