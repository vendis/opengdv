
OUTDIR=data

all:  overview fields valuemap

valuemap: $(OUTDIR)/valuemap.xml

overview: $(OUTDIR)/overview.html

fields: $(OUTDIR)/fields.txt

# Generate an HTML overview of all records
$(OUTDIR)/overview.html: overview.xsl satzarten.xml
	@mkdir -p `dirname $@`
	xsltproc -o $@ overview.xsl satzarten.xml 

# Produce a more concise summary of all records
# in an XML format that can be used to build a parser
$(OUTDIR)/feldnamen.xml: feldnamen.xsl satzarten.xml
	@mkdir -p `dirname $@`
	xsltproc -o $@ feldnamen.xsl satzarten.xml 

$(OUTDIR)/fields.txt: fields-compact.xsl $(OUTDIR)/feldnamen.xml
	xsltproc fields-compact.xsl $(OUTDIR)/feldnamen.xml | sed -e '/^ *$$/d' > $@

# Extract all <Werte> into a sane XML format
$(OUTDIR)/values.xml: values.xsl satzarten.xml
	@mkdir -p `dirname $@`
	xsltproc -o $@ values.xsl satzarten.xml 

# Reduce the values into a condensed list of maps
# with a list of which values are used where
# We actually use a handedited version of this
$(OUTDIR)/valuemap.xml: $(OUTDIR)/values.xml
	./valuemap.rb $< > $@

# We hand edit the generated valuemap.xml and generate the compacted
# file from that
$(OUTDIR)/values.txt: valuemap.xml valuemap-compact.xsl
	@mkdir -p `dirname $@`
	xsltproc valuemap-compact.xsl valuemap.xml | sed -e '/^ *$$/d' > $@
