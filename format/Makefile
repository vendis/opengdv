
all:  overview.html rectypes.txt valuemap.txt

# Generate an HTML overview of all records
overview.html: overview.xsl satzarten.xml
	xsltproc -o $@ overview.xsl satzarten.xml 

# Produce a more concise summary of all records
# in an XML format that can be used to build a parser
rectypes.xml: rectypes.xsl satzarten.xml
	xsltproc -o $@ rectypes.xsl satzarten.xml 

rectypes.txt: rectypes-compact.xsl rectypes.xml
	xsltproc rectypes-compact.xsl rectypes.xml | sed -e '/^ *$$/d' > $@

# Reduce the values into a condensed list of maps
# by extracting all <Werte> into a sane XML format
# with a list of which values are used where
# We actually use a handedited version of this
valuemap.xml: valuemap.xsl satzarten.xml
	xsltproc -o /tmp/valuemap.xml valuemap.xsl satzarten.xml 
	./valuemap.rb /tmp/valuemap.xml > $@

# We hand edit the generated valuemap.xml and generate the compacted
# file from that
valuemap.txt: valuemap.xml valuemap-compact.xsl
	xsltproc valuemap-compact.xsl valuemap.xml | sed -e '/^ *$$/d' > $@

clean:
	rm -f overview.html rectypes.xml rectypes.txt valuemap.txt