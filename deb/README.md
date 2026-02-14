# Missing Deb Files

(Some of) These files used to exist within the [ISC BIND9 PPA](https://launchpad.net/~isc/+archive/ubuntu/bind), however once focal transitioned out of support those files went away.

These files have been re-created using `dpkg-repack` and distributed here as-is.

These can be re-extracted using:

```sh
docker run --rm -v .:/deb -it --entrypoint "/bin/bash" registry.shanemcc.net/mydnshost-public/bind:9.16.21-old -c "/deb/extract.sh"
```

Unfortunately, these are not be a *perfect* replica of the original deb's due to some missing files from our source image:

```
/usr/share/doc/bind9/README.Debian
/usr/share/doc/bind9/README.gz
/usr/share/man/man1/arpaname.1.gz
/usr/share/man/man1/named-rrchecker.1.gz
/usr/share/man/man5/named.conf.5.gz
/usr/share/man/man5/rndc.conf.5.gz
/usr/share/man/man8/ddns-confgen.8.gz
/usr/share/man/man8/dnssec-coverage.8.gz
/usr/share/man/man8/dnssec-importkey.8.gz
/usr/share/man/man8/filter-aaaa.8.gz
/usr/share/man/man8/named-journalprint.8.gz
/usr/share/man/man8/named-nzd2nzf.8.gz
/usr/share/man/man8/named.8.gz
/usr/share/man/man8/nsec3hash.8.gz
/usr/share/man/man8/tsig-keygen.8.gz
/usr/share/man/man1/delv.1.gz
/usr/share/man/man1/dig.1.gz
/usr/share/man/man1/dnstap-read.1.gz
/usr/share/man/man1/mdig.1.gz
/usr/share/man/man1/nslookup.1.gz
/usr/share/man/man1/nsupdate.1.gz
/usr/share/man/man1/host.1.gz
/usr/share/man/man8/dnssec-cds.8.gz
/usr/share/man/man8/dnssec-checkds.8.gz
/usr/share/man/man8/dnssec-dsfromkey.8.gz
/usr/share/man/man8/dnssec-keyfromlabel.8.gz
/usr/share/man/man8/dnssec-keygen.8.gz
/usr/share/man/man8/dnssec-keymgr.8.gz
/usr/share/man/man8/dnssec-revoke.8.gz
/usr/share/man/man8/dnssec-settime.8.gz
/usr/share/man/man8/dnssec-signzone.8.gz
/usr/share/man/man8/dnssec-verify.8.gz
/usr/share/man/man8/named-checkconf.8.gz
/usr/share/man/man8/named-checkzone.8.gz
/usr/share/man/man8/rndc-confgen.8.gz
/usr/share/man/man8/rndc.8.gz
/usr/share/man/man8/named-compilezone.8.gz
/usr/share/doc/libfstrm0/README.md
```
