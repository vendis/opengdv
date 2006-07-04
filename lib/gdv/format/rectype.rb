module GDV::Format

    class FormatError < RuntimeError
    end

    class RecordError < RuntimeError
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
                raise FormatError, "No field named #{name} in #{self.rectype.satz}:#{self.rectype.sparte}:#{self.nr}"
            end
            @field_index[name]
        end

        def inspect
            "  nr = #{nr}\n  fields = #{fields.inspect}"
        end

        def to_s
            "<Part:#{rectype.satz}:#{rectype.sparte}:#{nr}>"
        end

        def rectype=(rt)
            unless rectype.nil?
                raise FormatError, "RecType already set for #{self}"
            end
            @rectype = rt
        end

        def finalize
            @fields.each do |f|
                f.finalize
                if @field_index.key?(f.name)
                    raise FormatError, "Duplicate field #{f.name}"
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
            # Seems to be true based on some examples
            if @name == :snr && values == ["1"]
                values << ' '
            end
            @pos = pos
            @len = len
            @type = type
            @values = values.uniq
            @label = label
            @part = nil
        end

        def extract(record)
            record[pos-1..pos+len-2]
        end

        def const?
            type == 'const'
        end

        def to_s
            "<Field[#{nr}]#{type}:#{pos}+#{len}>\n"
        end

        def part=(p)
            unless part.nil?
                raise FormatError, "Part already set for #{self}"
            end
            @part = p
        end
        
        def finalize
            if const?
                if values.empty?
                    raise FormatError, 
                    "Values can not be empty for const fields"
                end
                values.each do |v|
                    if len != v.size
                        raise FormatError, 
                        "Value #{value} must have exactly #{len} chars"
                    end
                end
            else
                unless values.empty?
                    raise FormatError, 
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

end

