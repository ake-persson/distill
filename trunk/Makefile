NAME=distill
VERSION=$(shell cat VERSION)
RELEASE=$(shell cat RELEASE)
OSREL=el6
TMPDIR=/tmp/${NAME}-${VERSION}-${RELEASE}
ASCIIDOC_FORMAT=docbook
XSL_ARGS=--stringparam html.stylesheet css/default.css --stringparam admon.graphics 1 --stringparam toc.section.depth 0 --stringparam admon.textlabel 0
XSL_FO_ARGS=--stringparam paper.type A4 --stringparam body.font.master 10
STYLESHEETS_DIR=/usr/share/sgml/docbook/xsl-stylesheets
SGML_CATALOG_FILES=file:////usr/share/sgml/docbook/xml-dtd-4.5-1.0-51.el6/catalog
export SGML_CATALOG_FILES

all: rpm

clean:
	rm -rf ${TMPDIR}
	rm -f *.rpm
	rm -f *.xml
	rm -f *.fo
	rm -f *.pdf
	rm -f *.html
	rm -f *.1
	rm -f *.5

xml:
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o distill.1.xml doc/distill.1.asc
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o enc-lookup.1.xml doc/enc-lookup.1.asc
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o distill.conf.5.xml doc/distill.conf.5.asc
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o distill_schema.1.xml doc/distill_schema.1.asc
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o distill_admin_guide.xml doc/distill_admin_guide.asc
	asciidoc -s -b ${ASCIIDOC_FORMAT} -d article -o distill_schema_admin_guide.xml doc/distill_schema_admin_guide.asc

html: xml
	xsltproc ${XSL_ARGS} --nonet --catalogs --output index.html ${STYLESHEETS_DIR}/xhtml/docbook.xsl doc/admin_guide.xml

fo: xml
#	xsltproc --nonet --catalogs ${XSL_FO_ARGS} --output admin_guide.fo ${STYLESHEETS_DIR}/fo/docbook.xsl doc/admin_guide.xml
	xsltproc --nonet --catalogs ${SL_FO_ARGS} --output admin_guide.fo doc/custom.xsl doc/admin_guide.xml

pdf: fo
	fop -q -r -pdf admin_guide.pdf -fo admin_guide.fo

man:
	asciidoc -b ${ASCIIDOC_FORMAT} -d manpage -o distill.1.xml doc/distill.1.asc
	asciidoc -b ${ASCIIDOC_FORMAT} -d manpage -o enc-lookup.1.xml doc/enc-lookup.1.asc
	asciidoc -b ${ASCIIDOC_FORMAT} -d manpage -o distill.conf.5.xml doc/distill.conf.5.asc
	asciidoc -b ${ASCIIDOC_FORMAT} -d manpage -o distill_schema.1.xml doc/distill_schema.1.asc
	xsltproc --nonet -o distill.1 --catalogs $(STYLESHEETS_DIR)/manpages/docbook.xsl distill.1.xml
	xsltproc --nonet -o enc-lookup.1 --catalogs $(STYLESHEETS_DIR)/manpages/docbook.xsl enc-lookup.1.xml
	xsltproc --nonet -o distill.conf.5 --catalogs $(STYLESHEETS_DIR)/manpages/docbook.xsl distill.conf.5.xml
	xsltproc --nonet -o distill_schema.1 --catalogs $(STYLESHEETS_DIR)/manpages/docbook.xsl distill_schema.1.xml

pre:
	[ "`id -u`" -eq 0 ] && yum -y install tidy asciidoc libxslt docbook-style-xsl docbook5-style-xsl perl-Perl-Critic perltidy fop

rpm: html man
	mkdir -p ${TMPDIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
	sed -e "s/%VERSION%/${VERSION}/g" -e "s/%RELEASE%/${RELEASE}.${OSREL}/g" ${NAME}.spec > ${TMPDIR}/${NAME}.spec
	rsync -a --exclude \.svn etc ${TMPDIR}/SOURCES/
	rsync -a --exclude \.svn bin ${TMPDIR}/SOURCES/
	rsync -a --exclude \.svn cgi ${TMPDIR}/SOURCES/
	rsync -a --exclude \.svn lib ${TMPDIR}/SOURCES/
	rsync -a --exclude \.svn html ${TMPDIR}/SOURCES/
	sed -e "s/%VERSION%/${VERSION}/g" -i ${TMPDIR}/SOURCES/etc/distill-doc.conf.httpd
	cp *.1 ${TMPDIR}/SOURCES/
	cp *.5 ${TMPDIR}/SOURCES/
	cp *.html ${TMPDIR}/SOURCES/html
	cp LICENSE ${TMPDIR}/SOURCES/
	rpmbuild -vv -bb --target="noarch" --clean --define "_topdir ${TMPDIR}" ${TMPDIR}/${NAME}.spec
	find ${TMPDIR}/RPMS/ -type f -name '*.rpm' -print0 | xargs -0 -I {} mv {} ./
