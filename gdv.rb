
require 'stringio'

module GDV

    def self.version
        "0.0.1"
    end

    def self.format_path
        File::join(File::dirname(__FILE__), "format")
    end

    module Model

        class ModelError < RuntimeError
        end

        class RecType
            attr_reader :satz, :sparte, :parts
            def initialize(satz, sparte, parts)
                @satz = satz
                @sparte = sparte
                @parts = parts
                @parts.each do |p|
                    p.rectype = self
                end
            end

            def matches?(record)
                parts.each do |p|
                    return p if p.matches?(record)
                end
            end

            def inspect
                "satz = #{satz}\nsparte = #{sparte}\n parts = #{parts.inspect}"
            end

            def finalize
              @parts.each { |p| p.finalize }
            end
        end
        
        class Part
            attr_reader :nr, :fields, :key_fields
            attr_accessor :rectype

            def initialize(nr, fields)
                @nr = nr
                @fields = fields
                @key_fields = fields.select { |f| f.const? }
                @fields.each do |f|
                    f.part = self
                end
                @field_index = {}
            end

            def field_at(pos, len)
                @fields.each do |f|
                    if f.pos == pos && f.len == len
                        return f
                    end
                end
                nil
            end

            def field?(name)
                @field_index.key?(name)
            end

            def [](name)
                unless field?(name)
                    raise ModelError, "No field named #{name} in #{self.rectype.satz}:#{self.rectype.sparte}:#{self.nr}"
                end
                @field_index[name]
            end

            def matches?(record)
                key_fields.each do |f|
                    unless f.matches?(record)
                        return false
                    end
                end
            end

            def inspect
                "  nr = #{nr}\n  fields = #{fields.inspect}"
            end

            def to_s
                "<Part:#{rectype.satz}:#{rectype.sparte}:#{nr}>"
            end

            def rectype=(rt)
                unless rectype.nil?
                    raise ModelError, "RecType already set for #{self}"
                end
                @rectype = rt
            end

            def finalize
                @fields.each do |f|
                    f.finalize
                    if @field_index.key?(f.name)
                        raise ModelError, "Duplicate field #{f.name}"
                    end
                    @field_index[f.name] = f
                end
            end
        end
        
        class Field
            attr_reader :nr, :name, :pos, :len, :type, :values, :label
            attr_accessor :part

            def initialize(nr, name, pos, len, type, values, label)
                @nr = nr
                if name.nil? || name.size == 0
                    name = "field#{nr}"
                end
                if name == "blank" || name == "waehrung"
                    # For these fields, we don't care too much about their name
                    name = "#{name}#{nr}"
                end
                @name = name.to_sym
                @pos = pos
                @len = len
                @type = type
                @values = values.uniq
                @label = label
                @part = nil
            end

            def extract(record)
                record[pos..pos+len-1]
            end

            def const?
                type == 'const'
            end

            def matches?(record)
                return true unless const?
                return values.include?(extract(record))
            end

            def to_s
                "<Field[#{nr}]#{type}:#{pos}+#{len}>\n"
            end

            def part=(p)
                unless part.nil?
                    raise ModelError, "Part already set for #{self}"
                end
                @part = p
            end
            
            def finalize
                if const?
                    if values.empty?
                        raise ModelError, 
                        "Values can not be empty for const fields"
                    end
                    values.each do |v|
                        if len != v.size
                            raise ModelError, 
                            "Value #{value} must have exactly #{len} chars"
                        end
                    end
                else
                    unless values.empty?
                        raise ModelError, 
                        "Values can only be given for const fields"
                    end
                end
            end
        end

        class Path
            attr_accessor :satz, :teil, :nr, :sparte
            def initialize(satz, teil, nr, sparte)
                @satz = satz
                @teil = teil
                @nr = nr
                @sparte = sparte
            end
        end

        class Typ
            attr_accessor :name, :paths, :values
            def initialize(name, paths, values)
                @name = name
                @paths = paths
                @values = values
            end
        end

        class IndexNode
            attr_reader :field, :children, :parts, :parent
            
            def initialize(parent, field, part)
                log "node #{pf(field)} : #{part}"
                @parent = parent
                @field = field
                @children = {}
                @parts = {}
                field.values.each { |v| @parts[v] = part }
            end


            def pf(field)
                return "no field" unless field
                "#{field.name}@#{field.pos}+#{field.len}=#{field.values}"
            end

            def unused_fields(part1, part2)
                key_fields = part1.key_fields.clone
                p = self
                while p
                    f = part1.field_at(p.field.pos, p.field.len)
                    key_fields.delete(f)
                    p = p.parent
                end
                key_fields = key_fields.select do |kf|
                    part2.field_at(kf.pos, kf.len)
                end
                key_fields
            end

            def insert(part)
                log "Insert #{part} for #{pf(field)}"
                f = part.field_at(field.pos, field.len)
                if f.nil? || ! f.const?
                    raise ModelError, "Incompatible fields #{pf(f)}"
                end
                f.values.each do |value|
                    log "Value: #{value} Child: #{children.key?(value)} Part: #{parts.key?(value)} "
                    if children.key?(value)
                        log "Insert into child #{value}"
                        return children[value].insert(part)
                    elsif parts.key?(value)
                        # Need to split and find another field to 
                        # discriminate by
                        old_part = parts[value]
                        log "Splitting #{old_part} at #{value}"
                        key_fields = unused_fields(old_part, part)
                        if key_fields.empty?
                            raise_no_key_field_error(old_part, part)
                        end
                        new_field = key_fields[0]
                        log "new_field: #{pf(new_field)} at #{value}"
                        children[value] = IndexNode.new(self, new_field, 
                                                        old_part)
                        parts.delete(value)
                        children[value].insert(part)
                        msg = ".." * depth
                        log "new_field: #{pf(new_field)} at #{value} #{msg}"
                    else
                        log "Adding part #{pf(f)}"
                        parts[value] = part
                    end
                end
            end
            
            def print(sio=nil)
                sio = StringIO.new unless sio
                ind = "    " * depth
                sio.puts "#{ind}#{field.name}@#{field.pos}+#{field.len}"
                parts.each do |v, p|
                    sio.puts "#{ind}  #{v} -> #{p}"
                end
                children.sort.each do |v, c|
                    sio.puts "#{ind}  #{v} ==>"
                    c.print(sio)
                end
                return sio.string
            end

            def depth
                p = self
                depth = 0
                while p
                    depth += 1
                    p = p.parent
                end
                return depth
            end

            def leaves
                result = children.values.inject([]) { |r, c| r + c.leaves }
                result + parts.values
            end

            def height
                if children.empty?
                    1
                else
                    children.values.collect{ |c| c.height }.max + 1
                end
            end

            private
            def raise_no_key_field_error(old_part, part)
                msg = %{No fields left to add part #{part}
#{old_part} #{old_part.key_fields.collect{ |f| pf(f) }.join(" ")}
#{part} #{part.key_fields.collect{ |f| pf(f) }.join(" ")}
}
                raise ModelError, msg
            end

            def log(msg)
                puts msg if false
            end
        end
    end

    class Parser

        class KeyFieldError < RuntimeError
        end

        class RecordError < RuntimeError
        end

        class << self
            attr_reader :rectypes, :values
        end

        def parse(io)
            cnt = 0
            match = 0
            rectypes = Parser::rectypes
            io.each_line do |l|
                l.chomp!
                if l.size != 256
                    raise RecordError, "Expected line of 256 bytes, but got #{l.size}"
                end
                rectypes.each do |rt|
                    if rt.matches?(l)
                        match += 1
                    end
                end
                cnt += 1
                puts "  #{cnt}" if cnt % 100 == 0
            end
            puts "#{cnt} lines, #{match} matches"
        end

        def parse_file(name)
            File.open(name) do |f|
                parse(f)
            end
        end

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
                        all << Model::RecType.new(a[0], a[1], parts)
                        parts = []
                    when "T":
                        parts << Model::Part.new(a[0].to_i, fields)
                        fields = []
                    when "F":
                        nr, name, pos, len, type, v, label = a
                        nr = nr.to_i
                        pos = pos.to_i
                        len = len.to_i
                        v = "" if v.nil?
                        values = v.split(",")
                        fields << Model::Field.new(nr, name, pos, len, 
                                                   type, values, label)
                    end
                end
            rescue Model::ModelError => e
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
                        paths << Model::Path.new(satz, teil, nr, sparte)
                    when "T":
                            name = a[0]
                        all[name.to_sym] = Model::Typ.new(name, paths, values)
                        paths = []
                        values = {}
                    end
                end
            rescue Model::ModelError => e
                puts "#{cnt}:#{e}"
                raise e
            end
            return all
        end

        def self.init
            File.open(File.join(GDV::format_path, 'rectypes.txt')) do |f|
                @rectypes = load_rectypes(f)
            end
            File.open(File.join(GDV::format_path, 'valuemap.txt')) do |f|
                @values = load_values(f)
            end
            #build_index
            return nil
        end

    end

end
