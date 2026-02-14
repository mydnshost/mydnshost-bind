#!/bin/bash

set -e

cd /deb
rm -Rfv ./*.deb
apt-get -y update
apt-get -y install dpkg-repack
sed -i 's/error("cannot find file/warning("cannot find file/g' /usr/bin/dpkg-repack
dpkg-repack bind9 bind9-dnsutils bind9-host bind9-libs bind9-utils libfstrm0 libuv1
