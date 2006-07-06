require 'gdv/format/rectype.rb'
require 'gdv/format/recindex.rb'
require 'gdv/format/reader.rb'

module GDV::Format
    def self.load_rectypes(file)
        fields = []
        parts = []
        all = []
        cnt = 0
        begin
            file.each_line do |line|
                cnt += 1
                line.chomp!
                a = line.split(/:/)
                typ = a.shift
                case typ
                when "K":
                        all << RecType.new(a[0], a[1], parts)
                    parts = []
                when "T":
                        parts << Part.new(a[0].to_i, fields)
                    fields = []
                when "F":
                        nr, name, pos, len, type, v, label = a
                    nr = nr.to_i
                    pos = pos.to_i
                    len = len.to_i
                    v = "" if v.nil?
                    values = v.split(",")
                    fields << Field.new(nr, name, pos, len, 
                                                type, values, label)
                end
            end
        rescue FormatError => e
            puts "#{cnt}:#{e}"
            raise e
        end
        all.each { |rt| rt.finalize }
        return all
    end

    def self.load_values(file)
        values = {}
        paths = []
        all = {}
        cnt = 0
        begin
            file.each_line do |line|
                cnt += 1
                line.chomp!
                a = line.split(/@/)
                typ = a.shift
                case typ
                when "V":
                        values[a[0]] = a[1]
                when "P":
                        satz, teil, nr, sparte = a
                    teil = teil.to_i
                    nr = nr.to_i
                    paths << Path.new(satz, teil, nr, sparte)
                when "T":
                        name = a[0]
                    all[name.to_sym] = Typ.new(name, paths, values)
                    paths = []
                    values = {}
                end
            end
        rescue FormatError => e
            path = "input"
            path = file.path if file.respond_to?(:path)
            puts "#{path}:#{cnt}:#{e}"
            raise e
        end
        return all
    end
    
    class << self
        attr_reader :rectypes, :values, :recindex
    end

    def self.classify(record)
        @recindex.classify(record)
    end

    def self.init
        if @rectypes.nil?
            File.open(File.join(GDV::format_path, 'rectypes.txt')) do |f|
                @rectypes = load_rectypes(f)
            end
        end
        if @values.nil?
            File.open(File.join(GDV::format_path, 'valuemap.txt')) do |f|
                @values = load_values(f)
            end
        end
        # Build the index for classifying records
        if @recindex.nil?
            parts = @rectypes.inject([]) { |l, rt| l + rt.parts }
            p = parts.shift
            @recindex = RecIndex.new(nil, p[:sid], p)
            parts.each do |p|
                GDV::log "\n\n** Tree:\n#{@recindex.print}\n"
                @recindex.insert(p)
            end
        end
    end
end
