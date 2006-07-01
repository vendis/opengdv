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

  # Create from path XML element
  def initialize(e)
    @name = e.attributes["name"]
    @name = "_typ#{ValueMap.next_count}" if @name.nil? || name.empty?
    @paths = []
    @values = {}
    @alias = []
    e.elements.each("alias") { |a| @alias << a.attributes["name"] }
    e.elements.each("path") { |p| @paths << FieldPath.new(p) }
    e.elements.each("value") do |v|
      @values[v.attributes["key"]] = v.text.strip
    end
  end
    
  def eql?(other)
    self == (other)
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
  <typ name="<%= h m.name %>">
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
