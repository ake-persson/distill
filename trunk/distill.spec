%define name distill
%define version %VERSION%
%define release %RELEASE%
%define buildroot %{_topdir}/BUILDROOT/
%define proxy http://unixproxy:3128

BuildRoot: %{buildroot}
Source: svn+ssh://svn/distill
Summary: Distill
Name: %{name}
Version: %{version}
Release: %{release}
License: GPLv3
Group: System
AutoReqProv: no
requires: perl, perl-CGI, perl-Config-Simple, perl-JSON, perl-YAML, perl-XML-Dumper, perl-XML-Parser, perl-Crypt-SSLeay, httpd

%description
Distill template engine for Puppet

%post
service httpd reload || true

%postun
service httpd reload || true

%prep
mkdir -p %{buildroot}/etc/distill/public
mkdir -p %{buildroot}/etc/httpd/conf.d
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/perl5
mkdir -p %{buildroot}/usr/share/doc/%{name}-%{version}/html
mkdir -p %{buildroot}/usr/share/man/{man1,man5}
mkdir -p %{buildroot}/var/{lib,log}/distill
cp %{_topdir}/SOURCES/etc/distill.conf %{buildroot}/etc/distill/distill.conf
cp %{_topdir}/SOURCES/etc/distill.conf.httpd %{buildroot}/etc/httpd/conf.d/distill.conf
cp %{_topdir}/SOURCES/etc/distill-doc.conf.httpd %{buildroot}/etc/httpd/conf.d/distill-doc.conf
cp -r %{_topdir}/SOURCES/bin/* %{buildroot}/usr/bin
cp -r %{_topdir}/SOURCES/cgi/* %{buildroot}/etc/distill/public
cp -r %{_topdir}/SOURCES/lib/perl5/* %{buildroot}/usr/share/perl5
cp -r %{_topdir}/SOURCES/html/* %{buildroot}/usr/share/doc/%{name}-%{version}/html
cp %{_topdir}/SOURCES/*.1 %{buildroot}/usr/share/man/man1
cp %{_topdir}/SOURCES/*.5 %{buildroot}/usr/share/man/man5
cp %{_topdir}/SOURCES/LICENSE %{buildroot}/usr/share/doc/%{name}-%{version}
gem install json-schema yajl-ruby colorize -q -p %{proxy} --no-rdoc --no-ri --bindir %{buildroot}/usr/bin --install-dir %{buildroot}/usr/lib/ruby/gems/1.8

%files
%defattr(-,root,root)
%attr(755,-,-)/usr/bin/*
%attr(755,-,-)/etc/distill/public/*
/usr/share/*
/usr/lib/ruby/gems/1.8/*

%config(noreplace) /etc/distill/distill.conf
%config(noreplace) /etc/httpd/conf.d/distill.conf
%config(noreplace) /etc/httpd/conf.d/distill-doc.conf

%defattr(-,apache,apache)
%dir /var/lib/distill
%dir /var/log/distill
