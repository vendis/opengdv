#! /usr/bin/ruby
# -*- coding: raw-text -*-

$:.unshift(File::join(File::dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'nokogiri'
require 'gdv'

FIELD_NAMES = {
    "Satzart" => "sid",
    "VuNr" => "vunr",
    'Buendelungskennzeichen' => 'bkz',
    'Sparte' => 'sparte',
    'Versicherungsschein-Nummer' => 'vsnr',
    'Folgenummer' => 'fnr',
    'GeschaeftsstelleVermittler' => 'verm',
    'Waehrungsschluessel' => 'waehrung',
    'SatzNr' => 'snr',
    'SatzNrRep' => 'snr2',
    'Leerstellen' => 'blank',
    'Art1' => 'Art'        # Only in 580.01 and 580.2
}

TYPE_NAMES = {
    'Alphanumerisch' => :string,
    'Datum' => :date,
    'Fließkomma' => :number,
    'FlieÃŸkomma' => :number,
    'Numerisch' => :number,
    'Uhrzeit' => :time,
    '' => :unknown
}

EMITTED_TYPE_MAPS = []

class String
   def to_underscore
     self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
           gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
   end
end

def progress(msg)
    $stderr.puts msg
end

def typename(fieldname, fdef)
    # FIXME: Handle value maps
    if ['sid', 'snr'].include?(fieldname)
        :const
    else
        vmap = fdef.xpath('wertetabelle')
        tname = vmap.xpath('technischerName').text
        if tname.empty?
            typ = fdef.xpath("datentyp").text
            TYPE_NAMES[typ] || typ.to_sym
        else
            typename = (tname.to_underscore + "_t").to_sym
            if ! EMITTED_TYPE_MAPS.include?(typename)
                vmap.xpath('alleWerteDerTabelle/eintrag').each do |e|
                    val = e.xpath('wert').text.strip
                    label = e.xpath('beschreibung').text.strip
                    puts "V:#{val}:#{label}"
                end
                puts "M:#{typename}:#{tname}"
                EMITTED_TYPE_MAPS << typename
            end
            typename
        end
    end
end

def add_overlay(parent, name, pos, len, val)
        parent.add_child("
<feldreferenz  overlay='true' pos='#{pos}' len='#{len}' const='#{val}'>
  <technischerName>#{name}</technischerName>
</feldreferenz>
")
end

progress "Parse XML"
doc = File.open(ARGV[0]) { |f| Nokogiri::XML(f) }
$stdout.reopen(ARGV[1])

rt = doc.xpath("/service/satzarten")
fields = doc.xpath("/service/felder")

#
# Patch some nonsense out of the DOM
#

# leerstellenreferenz -> feldreferenz
progress "Patch leerstellenreferenz"
doc.xpath("//leerstellenreferenz").each do |r|
    r.name = "feldreferenz"
    r["leerstellen"] = "true"
end

# technischerName SatzNr1, SatzNr2, ... -> SatzNr
progress "Rename variants of Satznummer"
satznr = [ "Satznummer" ] + (1..9).collect { |i| "SatzNr#{i}" }
satznr.each do |s|
    xpath = "//feldreferenz[name = 'Satznummer']/technischerName[. = '#{s}']"
    doc.xpath(xpath).each { |n| n.content = 'SatzNr' }
end

# same for variants of SatzNrnwiederholung
progress "Rename variants of Satznummernwiederholung"
xpath = "//feldreferenz[name = 'Satznummernwiederholung']/technischerName"
doc.xpath(xpath).each { |s| s.content = 'SatzNrW' }

#
# Massage the records that are hard to distinguish
#

# Add a field for a single space
fields.first.add_child("
<feld referenz='rectypes-space1'>
  <bytes>1</bytes>
</feld>
")

# Fix up 0220.030 Unfall - Wagnisdaten/-zusatz
#          Part 1: snr@49+1=1  snr2@250+1=1   spaces@251+6= ' '^6
#          Part 2: snr@49+1=2  f42@246+6=\d^6 skenn@256+1=X
#          Part 3: snr@43+1=3  snr2@250+1=3   lfdnr@251+6=[0-9]^6
#          Part 4: snr@49+1=4  snr2@250+1=4   spaces@251+6= ' '^6
#          Part 9: snr@60+1=9  snr2@250+1=9   lfdnr@251+6=[0-9]^6
# Modify things so that SatzNr and SatzNrWiederholung get
# swapped and add overlay fields as consts for the fields where
# we need to look at individual characters to discriminate
rec = rt.xpath("satzart[@referenz = 'BN-2003.02.11.22.50.11.849']")
rec.xpath(".//feldreferenz/technischerName[. = 'SatzNr']").each do |s|
    s.content = 'SatzNrRep'
end
rec.xpath(".//feldreferenz/technischerName[. = 'SatzNrW']").each do |s|
    s.content = 'SatzNr'
end

rec.xpath("satzanfang").each do |anf|
    partnr = anf['teilsatz']
    digits = (0..9).to_a.join(",")
    # Add overlay fields to allow discriminating
    ende = anf.xpath("following-sibling::satzende[1]").first
    if partnr == '1'
        add_overlay(ende, "skenn", 256, 1, ' ')
    elsif partnr == '2'
        add_overlay(ende, "skenn", 256, 1, 'X')
        xpath = "feldreferenz[technischerName = 'ZusaetzlicheSatzkennung']"
        ende.xpath(xpath).each { |f| f.unlink }
    elsif partnr == '3'
        add_overlay(ende, "skenn", 256, 1, digits)
    elsif partnr == '4'
        add_overlay(ende, "skenn", 256, 1, ' ')
    elsif partnr == '9'
        add_overlay(ende, "skenn", 256, 1, digits)
    else
        raise "unexpected part #{partnr}"
    end
end

# Fix up 0221.030 Unfall - Wagnisdaten/-zusatz
#          Part 2: snr@49+1=2                 skenn@256+1=X
#          Part 3: snr@43+1=3  snr2@250+1=3   lfdnr@251+6=[0-9]^6
rec = rt.xpath("satzart[@referenz = 'BN-2003.02.11.22.50.22.44']")
rec.xpath("satzanfang").each do |anf|
    partnr = anf['teilsatz']
    digits = (0..9).to_a.join(",")
    # Add overlay fields to allow discriminating
    ende = anf.xpath("following-sibling::satzende[1]").first
    if partnr == '2'
        add_overlay(ende, "skenn", 256, 1, 'X')
        xpath = "feldreferenz[technischerName = 'ZusaetzlicheSatzkennung']"
        ende.xpath(xpath).each { |f| f.unlink }
    elsif partnr == '3'
        add_overlay(ende, "skenn", 256, 1, digits)
    else
        raise "unexpected part #{partnr}"
    end
end

# Satz 0500 - Schadeninformationssatz
#   Part 1: snr@66+1=1  spaces@254+3 = '   '
#   Part 2: snr@256+1=2
# Split spaces in part 1 into two fields so that we compare ' ' against '2'
progress "Fix up 0500"
rec = rt.xpath("satzart[@referenz = 'BN-2003.02.11.22.50.28.393']").first
spaces = rec.xpath("*/feldreferenz[@referenz= 'leerstellen']").first
spaces.add_next_sibling("
<feldreferenz const=' ' referenz='rectypes-space1'>
  <technischerName>constSpace</technischerName>
</feldreferenz>
")

# Creatively, Bausparen calls Sparte Produkt. Rename it back to Sparte
progress "Rename Produkt to Sparte (Bausparen)"
doc.xpath("/service/satzarten//feldreferenz[name = 'Produkt'] | /service/felder/feld[name = 'Produkt']").each do |prod|
    prod.xpath("name|technischerName").each { |n| n.content = 'Sparte' }
end

# Add a 'const' attribute in feldreferenz for discrimnator fields
# We set 'const' to a comma-separated list of possible values,
# even though that's horrible XML
progress "Mark discriminators const"
rt.xpath("satzart").each do |rec|
    partnr = nil
    rec.xpath(".//feldreferenz").each do |f|
        if f.parent.name == 'satzanfang'
            partnr = f.parent['teilsatz'] || "1"
        end
        tname = f.xpath('technischerName').text
        val = rec.xpath("kennzeichnung/feldreferenz[@referenz = '#{f["referenz"]}']/auspraegung").text
        if tname == "Sparte"
            # In some records, like Bausparen, the referenz into kennzeichnung
            # is broken
            if val.empty?
                val = rec.xpath("kennzeichnung/feldreferenz[name = 'Sparte']/auspraegung").text
            end
            sparte, v = val.split(".")
            if sparte
                f["const"] = sparte
                if v
                    vals = v.split("").join(",")
                    xpr = nil
                    if sparte == "580"  # Satzart 580.01 / 580.2
                        xpr = ".//feldreferenz[name = 'Art']"
                    elsif sparte == "010" # Satzart 0220:010.0 / 0220:010.13
                        xpr = ".//feldreferenz[name = 'Wagnisart']"
                    elsif sparte == "020" # Satzart 0220.020.123
                        xpr = ".//feldreferenz[@referenz = 'BN-2003.02.11.22.50.11.349']"
                    end
                    if xpr
                        rec.xpath(xpr).each do |fref|
                            fref["const"] = vals
                        end
                    end
                end
            end
        elsif tname == "SatzNr" && partnr
            f["const"] = partnr
        elsif ! val.empty?
            f["const"] = val
        end
    end
end

progress "Process record types"
rt.xpath("satzart").each do |rec|
    fieldnr = 1
    flds = []
    parts = []
    partline = rec.line
    partnr = nil
    rec.xpath('*[preceding-sibling::entwurf]').each do |x|
        if x.name == 'satzanfang'
            if partnr
                parts << GDV::Format::Part.new(flds, :nr => partnr.to_i,
                                               :line => partline)
            end
            partnr = x['teilsatz']
            fieldnr = 1
            partline = x.line
            flds = []
        end
        x.xpath('self::feldreferenz|feldreferenz').each do |f|
            tname = f.xpath("technischerName").text
            tname = (FIELD_NAMES[tname] || tname).to_underscore
            fld = {
                :nr => fieldnr,
                :line => f.line,
                :name => tname,
                :label => f.xpath("name").text
            }
            val = nil
            fdef = fields.xpath("feld[@referenz = '#{f["referenz"]}']")
            if fdef.size == 0
                if f['leerstellen']
                    fld[:type] = :space
                elsif !f['const']
                    raise "Field without definition #{f}"
                end
            else
                fld[:len] = fdef.xpath("bytes").text.to_i
                fld[:type] = typename(fld[:name], fdef)
            end
            if val = f["const"]
                fld[:type] = :const
                val = val.split(",")
            end
            if fld[:type] == :number
                decimals = fdef.xpath("nachkommastellen").text
                val = [ decimals ] unless decimals.empty?
            end
            # 'Overlay' fields have a pos attribute
            # Those are fields that contain part of another field
            if f[:overlay] == 'true'
                fld[:len] = f[:len].to_i
                fld[:pos] = f[:pos].to_i
            end
            fld[:values] = val
            flds << GDV::Format::Field.new(fld)
            fieldnr += 1
        end
    end
    parts << GDV::Format::Part.new(flds, :nr => partnr, :line => partline)

    label = rec.xpath('name').text
    sid = rec.xpath("kennzeichnung/feldreferenz[name = 'Satzart']/auspraegung").text
    sparte = rec.xpath("kennzeichnung/feldreferenz[name = 'Sparte']/auspraegung").text
    rectype = GDV::Format::RecType.new(parts, :line => rec.line, :satz => sid,
                                       :sparte => sparte, :label => label)
    rectype.finalize
    rectype.emit
end
progress "Done"
