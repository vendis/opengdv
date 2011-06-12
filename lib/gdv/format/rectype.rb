require 'date'
require 'yaml'

module GDV::Format

    # The URI we use for our YAML objects. The date indicates the date
    # of the underlying GDV release
    YAML_URI = "tag:opengdv.vendis.org,2009-11-01"

    class FormatError < RuntimeError
    end

    class RecordError < RuntimeError
    end

    # Parse a date; the string +s+ must be exactly 8 bytes, in the format
    # +MMTTJJJJ+.
    # @return [Date] the date corresponding to +s+
    def self.parse_date(s)
        d = s[0,2].to_i
        m = s[2,2].to_i
        y = s[4,4].to_i
        return nil if y + m + d == 0
        d = 1 if d == 0
        m = 1 if m == 0
        Date.civil(y,m,d)
    end

    class RecType
        attr_reader :satz, :sparte, :line, :label, :parts
        def initialize(parts, h)
            @satz = h[:satz]
            @sparte = h[:sparte]
            @sparte = nil if @sparte == ""
            @line = h[:line]
            @label = h[:label]
            @parts = parts
            @part_index = {}
            @parts.each do |p|
                p.rectype = self
                p.fields.each do |f|
                    unless @part_index[f.name]
                        @part_index[f.name] = [p.nr, f.name]
                    end
                end
            end
        end

        def index(name)
            @part_index[name]
        end

        def inspect
            "@satz = #{satz}\n@sparte = #{sparte}\n@parts = #{parts.inspect}"
        end

        def to_s
            "rectype: @satz = #{satz}, @sparte = #{sparte}"
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

        yaml_as "#{YAML_URI}:rectype"

        def to_yaml(opts = {})
            YAML.quick_emit(self, opts) do |out|
                out.map(taguri, to_yaml_style) do |map|
                    map.add("path", parts.first.path)
                end
            end
        end

        def self.yaml_new(klass, tag, val)
            GDV::Format::Classifier::find_part(val["path"]).rectype
        end
    end

    class Part
        attr_reader :nr, :line, :fields, :key_fields
        attr_accessor :rectype, :path

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

        # Look a field up by its name or number
        def [](name)
            if name.is_a?(Fixnum)
                @fields[name - 1]
            else
                unless field?(name)
                    names = @field_index.keys.collect { |k| k.to_s }.sort
                    raise FormatError, "#{line}: No field named #{name} in #{self.rectype.satz}:#{self.rectype.sparte}:#{self.nr}. Possible fields: #{names.join(", ")}"
                end
                @field_index[name]
            end
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
                if f.len.nil? && f.type == :space
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

        # Return a +Line+ based on this part with a string that is filled
        # with the default values for each field
        def default
            unless @default
                raw = fields.collect { |f| f.default }.join("")
                @default = Line.new(raw, self)
            end
            @default
        end

        yaml_as "#{YAML_URI}:part"

        def to_yaml(opts = {})
            YAML.quick_emit(self, opts) do |out|
                out.map(taguri, to_yaml_style) do |map|
                    map.add("nr", @nr)
                    map.add("rectype", @rectype)
                end
            end
        end

        def self.yaml_new(klass, tag, val)
            val["rectype"].parts[val["nr"]-1]
        end

        def self.parse(fields, l)
            Part.new(fields, :line => l[1], :nr => l[2].to_i)
        end
    end

    class Field
        attr_reader :nr, :name, :type, :values, :label, :line
        attr_accessor :part, :pos, :len, :map
        attr_reader :precision

        def initialize(h)
            @map = h[:map]
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
                @precision = @values.shift.to_i
            else
                @values = @values.uniq
            end
            @label = h[:label]
            @part = nil
        end

        def uniquify_name!
            @name = "#{@name}_f#{@nr}"
        end

        # Return the raw string for this field from +record+
        def extract(record)
            record[pos-1..pos+len-2]
        end

        # Convert the value for this field in +record+. For mapped types,
        # return the entry from the map. For alphanumeric fields, strip
        # spaces and convert using the +enc+ if it is passed to convert
        # the character encoding
        # @param [String] record the raw record (a string of 256 bytes)
        # @param [Encoder] enc an optional encoder
        # @return [String, Fixnum, Date] the converted value for this
        # field
        def convert(record, enc = nil)
            s = extract(record)
            if mapped?
                map[s]
            elsif number?
                if precision > 0
                    s.to_i / (10.0 ** precision)
                else
                    s.to_i
                end
            elsif type == :date
                GDV::Format::parse_date(s)
            else
                if enc
                    Encoder.utf8(enc).convert(s.strip)
                else
                    s.strip
                end
            end
        end

        # Return the original mapped value of this field, not the override
        def orig_mapped(record)
          @map.orig_values[extract(record)] if @map
        end

        def const?
            type == :const
        end

        def number?
            type == :number
        end

        def mapped?
            ! @map.nil?
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
            if number?
                v = [ precision ]
            else
                v = values.join(",")
            end
            puts "F:#{line}:#{nr}:#{name}:#{pos}:#{len}:#{type}:#{v}:#{label}"
        end

        # Return a string holding the default value for this field
        def default
            if [:number, :date, :time].include?(type)
                "0" * len
            elsif type == :const
                values.first
            else
                " " * len
            end
        end

        def self.parse(l, maps={})
            v = l[7] || ""
            t = l[6].to_sym
            Field.new(:line => l[1],
                      :nr => l[2].to_i,
                      :name => l[3],
                      :pos => l[4].to_i,
                      :len => l[5].to_i,
                      :type => t,
                      :values => v.split(","),
                      :label => l[8], :map => maps[t])
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

    class ValueMap
        attr_accessor :label, :values, :orig_values

        def initialize(label, values, override)
            if override
                @label = override.label
                @values = override.values
            else
                @label = label
                @values = values
            end
            @orig_values = values
        end

        def [](k)
            values[k]
        end
    end

end
