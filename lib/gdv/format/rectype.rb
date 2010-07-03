module GDV::Format

    class FormatError < RuntimeError
    end

    class RecordError < RuntimeError
    end

    class RecType
        attr_reader :satz, :sparte, :line, :label, :parts
        def initialize(parts, h)
            @satz = h[:satz]
            @sparte = h[:sparte]
            @line = h[:line]
            @label = h[:label]
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

        def emit
            parts.each { |p| p.emit }
            puts "K:#{line}:#{satz}:#{sparte}:#{label}"
        end

        def self.parse(parts, l)
            RecType.new(parts, :line => l[1], :satz => l[2], :sparte => l[3],
                        :label => l[4])
        end
    end

    class Part
        attr_reader :nr, :line, :fields, :key_fields
        attr_accessor :rectype

        def initialize(fields, h)
            @nr = h[:nr]
            @line = h[:line]
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
                puts "FIELDS #{@field_index.keys.inspect}"
                raise FormatError, "#{line}: No field named #{name} in #{self.rectype.satz}:#{self.rectype.sparte}:#{self.nr}"
            end
            @field_index[name]
        end

        def inspect
            self.to_s
        end

        def to_s
            "<Part:#{rectype.satz}:#{rectype.sparte}:#{nr} (line #{line})>"
        end

        def rectype=(rt)
            unless rectype.nil?
                raise FormatError, "RecType already set for #{self}"
            end
            @rectype = rt
        end

        def finalize
            # Make sure field names are unique and compute the
            # length for the 'space' field which might be missing
            names = {}
            used = 0
            @warnings ||= []
            fields.each do |f|
                names[f.name] ||= 0
                names[f.name] += 1
                # 'Overlay' fields have pos set
                used += f.len if f.len && f.pos == 0
            end
            pos = 1
            fields.each do |f|
                f.pos = pos if f.pos == 0
                if f.len.nil? && f.type == 'space'
                    if used
                        f.len = 256 - used
                        used = nil
                    else
                        raise FormatError, "#{line}: two fields without a length"
                    end
                end
                raise FormatError, "#{line}: missing length #{f.inspect}" if f.len.nil?
                pos += f.len
            end
            names.keys.each do |n|
                if names[n] > 1
                    fields.select { |f| f.name == n }.each do |f|
                        @warnings << "rename #{f.nr}: #{f.name}"
                        f.uniquify_name!
                    end
                end
            end
            fields.each do |f|
                f.finalize
                if @field_index.key?(f.name)
                    raise FormatError, "Duplicate field #{f.name}"
                end
                @field_index[f.name] = f
            end
        end

        def emit
            fields.each { |f| f.emit }
            @warnings.each { |w| puts "C:#{w}" }
            puts "T:#{line}:#{nr}"
        end

        def self.parse(fields, l)
            Part.new(fields, :line => l[1], :nr => l[2].to_i)
        end
    end

    class Field
        attr_reader :nr, :name, :type, :values, :label, :line
        attr_accessor :part, :pos, :len
        attr_reader :precision

        def initialize(h)
            @line = h[:line]
            @nr = h[:nr]
            if h[:name].empty?
                @name = :"field#{nr}"
            else
                @name = h[:name].to_sym
            end
            if @name == "blank" || @name == "waehrung"
                # For these fields, we don't care too much about their name
                @name = :"#{@name}#{@nr}"
            end
            # Seems to be true based on some examples
            @values = h[:values] || []
            if @name == :snr && @values == ["1"]
                @values << ' '
            end
            @pos = h[:pos] || 0
            @len = h[:len]
            @type = h[:type]
            if number?
                @precision = @values.shift
            else
                @values = @values.uniq
            end
            @label = h[:label]
            @part = nil
        end

        def uniquify_name!
            @name = "#{@name}_f#{@nr}"
        end

        def extract(record)
            record[pos-1..pos+len-2]
        end

        def convert(record)
            extract(record)
        end

        def const?
            type == 'const'
        end

        def number?
            type == 'number'
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
                    "#{line}:Values can not be empty for const fields #{self.inspect}"
                end
                values.each do |v|
                    if len != v.size
                        raise FormatError,
                        "#{line}:Value #{v} must have exactly #{len} chars"
                    end
                end
            else
                unless values.empty?
                    raise FormatError,
                    "#{line}:Values can only be given for const fields #{self.inspect}"
                end
            end
        end

        def emit
            v = values.join(",")
            puts "F:#{line}:#{nr}:#{name}:#{pos}:#{len}:#{type}:#{v}:#{label}"
        end

        def self.parse(l)
            v = l[7] || ""
            Field.new(:line => l[1],
                      :nr => l[2].to_i,
                      :name => l[3],
                      :pos => l[4].to_i,
                      :len => l[5].to_i,
                      :type => l[6],
                      :values => v.split(","),
                      :label => l[8])
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
