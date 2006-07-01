#! /usr/bin/ruby
require 'gdv'
require "rexml/document"
require "rexml/streamlistener"
require 'yaml'

f = File.new(ARGV[0])
fields = []
parts = []
all = []
f.each_line do |line|
    a = line.split(/:/)
    typ = a.shift
    case typ
        when "K":
            all << GDV::Model::Satzart.new(a[0], a[1], parts)
            parts = []
        when "T":
            parts << GDV::Model::Part.new(a[0].to_i, fields)
            fields = []
        when "F":
            nr, name, pos, len, type, value, label = a
            nr = nr.to_i
            pos = pos.to_i
            len = len.to_i
            fields << GDV::Model::Field.new(nr, name, pos, len, type, value, label)
    end
end
puts "Satzarten: #{all.size}"
p all[17]

exit(0)
class Listener 
    include REXML::StreamListener
    attr_reader :records

    def initialize()
        @buf = ""
    end

    def tag_start(name, attrs)
        m = "start_#{name}".downcase
        if respond_to?(m)
            method(m).call(attrs)
        else
            raise RuntimeError, "Unimplemented start for #{name}"
        end
    end

    def tag_end(name)
        m = "end_#{name}".downcase
        if respond_to?(m)
            method(m).call()
        else
            raise RuntimeError, "Unimplemented end for #{name}"
        end
        @buf = ""
    end

    def text(text)
        @buf += text
    end

    def start_satzarten(attrs)
        @records = []
    end

    def start_satzart(attrs)
        #puts "**Start satzart"
    end

    def start_teil(attrs)
    end
    
    def start_feld(attrs)
    end
    
    def start_label(attrs)
    end

    def end_satzarten()
    end

    def end_satzart()
    end

    def end_teil()
    end
    
    def end_feld()
    end
    
    def end_label()
    end

    
end

def a(e, n)
    e.attributes[n]
end

source = File.new(ARGV[0])
lsnr = Listener.new
REXML::Document.parse_stream(source, lsnr)



exit(0)
file = File.open( ARGV[0] )
doc = REXML::Document.new file

all = []
doc.elements.each("/satzarten/satzart") do |satzart|
    parts = []
    satzart.elements.each("teil") do |teil|
        fields = []
        teil.elements.each("feld") do |feld|
            label = feld.get_text("label").value
            nr = a(feld, 'nr').to_i
            name = a(feld, 'name')
            pos = a(feld, 'pos').to_i
            len = a(feld, 'len').to_i
            type = a(feld, 'type')
            value = a(feld, 'value')
            fields << GDV::Model::Field.new(nr, name, pos, len, type, value, label)
        end
        parts << GDV::Model::Part.new(a(teil, 'nr').to_i, fields)
    end
    all << GDV::Model::Satzart.new(a(satzart, 'satz'),
                                a(satzart, 'sparte'), parts)
end

File.open("build/fields.yaml", 'w') do |out|
    YAML.dump(all, out)
end

p all.size
