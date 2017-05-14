FROM nguoianphu/docker-dns

MAINTAINER Shane Mc Cormack <shanemcc@gmail.com>

COPY bind/* /etc/bind/
COPY mydnshost-entrypoint.sh /

RUN mkdir /bind && chmod +x /mydnshost-entrypoint.sh

ENTRYPOINT [ "/mydnshost-entrypoint.sh" ]
CMD [""]
