#! /usr/bin/ruby

# Run this script over the output of
# xsltproc values.xsl /tmp/satzarten.xml > /tmp/valuemap.xml
# valuemap.rb /tmp/valuemap.xml > valuemap.xml

require "rexml/document"
require "erb"

class FieldPath
  attr_reader :satz, :teil, :nr, :sparte

  def to_s
    if sparte.empty?
      "#{satz}.#{teil}:#{nr}"
    else
      "#{satz}.#{teil}.#{sparte}:#{nr}"
    end
  end

  # Create from path XML element
  def initialize(e)
    @satz = e.attributes["satz"]
    @teil = e.attributes["teil"]
    @nr   = e.attributes["nr"]
    @sparte = e.attributes["sparte"]
  end

end

class ValueMap
  attr_reader :paths, :values, :name, :alias
  
  NAME_MAP = {
    "_typ1" => [ "absender_art_t", 362134658 ],
    "_typ2" => [ "sparte_t", 1825682829 ],
    "_typ3" => [ "gevo_t", 527246070 ],
    "_typ4" => [ "autorisierung_t", 2620785738 ],
    "_typ5" => [ "boolean", 4044219356 ],
    "_typ7" => [ "anrede_t", 2247829527 ],
    "_typ8" => [ "laenderkennz_t", 1935882545 ],
    "_typ9" => [ "address_kennz_t", 1112559737 ],
    "_typ10" => [ "zielgruppe_t", 1952189333 ],
    "_typ12" => [ "geschlecht_t", 1830612605 ],
    "_typ14" => [ "kommtyp_t", 3273422001 ],
    "_typ18" => [ "zahlungsart_t", 780629530 ],
    "_typ19" => [ "fam_stand_t", 479365104 ],
    "_typ24" => [ "rechtsform_t", 2092709775 ],
    "_typ26" => [ "bankverb_t", 2659700852 ],
    "_typ30" => [ "bezug_vn_t", 4111449760 ],
    "_typ32" => [ "inkasso_t", 2559002436 ],
    "_typ33" => [ "zahlungsweise_t", 1630518295 ],
    "_typ34" => [ "vertragsstatus_t", 2290374739 ],
    "_typ35" => [ "abgangsgrund_t", 3453120067 ],
    "_typ37" => [ "waehrung_t", 894664913 ],
    "_typ59" => [ "sign_t", 4276933552 ],
    "_typ87" => [ "summenart_t", 1944200830 ],
    "_typ92" => [ "jahres_maximierung_t", 3982444481 ],
    "_typ141" => [ "aenderungsgrund_t", 3283809242 ],
    "_typ212" => [ "bauartklasse_t", 2346596949 ],
    "_typ213" => [ "gefahrenerhoehung_t", 2383799713 ],
    "_typ277" => [ "mengen_schluessel_t", 2485354923 ],
    "_typ353" => [ "wertungsbasis_t", 794488123 ],
    "_typ609" => [ "summen_art_t", 2022195149 ],
    "_typ610" => [ "summenanpassung_t", 662870067 ],
  }

  def ValueMap::lookup_name(vm)
    hsh = vm.hash
    name = "_typ#{ValueMap.next_count}"
    if NAME_MAP.key?(name)
      n, h = NAME_MAP[name]
      if hsh != h
        $stderr.puts "Not renaming #{name} to #{n}, hash #{hsh} != #{h}"
      else
        return n
      end
    end
    return name
  end

  # Create from path XML element
  def initialize(e)
    @name = e.attributes["name"]
    # @name = "_typ#{ValueMap.next_count}" if @name.nil? || name.empty?
    @paths = []
    @values = {}
    @alias = []
    e.elements.each("alias") { |a| @alias << a.attributes["name"] }
    e.elements.each("path") { |p| @paths << FieldPath.new(p) }
    e.elements.each("value") do |v|
      @values[v.attributes["key"]] = v.text.strip
    end
    @name = ValueMap::lookup_name(self)
  end
    
  def eql?(other)
    self == (other)
  end

  def hash
    result = 0
    values.keys.sort.each do |k|
      result = (41 * result + 23 * k.hash + values[k].hash) % 2**32
    end
    result
  end

  def ==(other)
    return true if self.equal?(other)
    return false unless other.instance_of?(self.class)
    return values == other.values
  end

  def merge(other)
    if other.name[0..3] != "_typ"
      if name[0..3] == "_typ"
        @name = other.name
      else
        @alias << other.name
      end
    end
    @paths += other.paths
  end

  private

  @@count = 0
  def self.next_count
    @@count += 1
  end

end

file = File.open( ARGV[0] )
doc = REXML::Document.new file

types = []
doc.elements.each("/types/typ") do |typ|
  vm = ValueMap.new(typ)
  types.each do |m|
    if m == vm
      m.merge(vm)
      vm = nil
      break
    end
  end
  types << vm unless vm.nil?
end

template =
%q{<?xml version="1.0" encoding="UTF-8"?>
<types>
<% for m in types do %>
  <typ name="<%= h m.name %>" hash="<%= m.hash %>">
<% for a in m.alias.sort do %>
    <alias name="<%= h a %>"/>
<% end %>
<% for p in m.paths do %>
    <path satz="<%= h p.satz %>" teil="<%= h p.teil %>" nr="<%= h p.nr %>" sparte="<%= h p.sparte %>"/>
<% end %>
<% m.values.keys.sort.each do |k| %>
    <value key="<%= h k %>"><%= h m.values[k] %></value>
<% end %>
  </typ>
<% end %>
</types>
}

include ERB::Util
puts ERB.new(template, 0, '>').result(binding)
exit 0

puts '<?xml version="1.0" encoding="UTF-8"?>'
puts '<types>'
types.each do |m|
  puts "  <typ name=\"#{m.name}\">"
  m.alias.each do |a|
    puts "    <alias name=\"#{a}\"/>"
  end
  m.paths.each do |p|
    puts "    <path satz=\"#{p.satz}\" teil=\"#{p.teil}\" nr=\"#{p.nr}\" sparte=\"#{p.sparte}\"/>"
  end
  m.values.each do |k,v|
    puts "    <value key=\"#{k}\">#{v}</value>"
  end
  puts "  </typ>"
end
puts '</types>'
