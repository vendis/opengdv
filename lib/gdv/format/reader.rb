module GDV::Format

    class ReaderError < RuntimeError
        attr_reader :path, :lineno
        def initialize(io, lineno)
            @path = "(input)"
            @path = io.path if io.respond_to?(:path)
            @lineno = lineno
        end

        def message
            "#{path}:#{lineno}:#{details}"
        end

        def details
            "Lesefehler"
        end
    end

    class RecordSizeError < ReaderError
    end

    class UnknownRecordError < ReaderError
    end

    class ParseError < ReaderError
        def initialize(io, lineno, cond)
            super(io, lineno)
            @cond = cond
        end

        def details
            "Satz mit Kennzeichnung #{@cond.inspect} erwartet"
        end
    end

    class Line
        attr_reader :part

        def initialize(raw, part)
            @raw = raw
            @part = part
        end

        def field(name)
            @part[name]
        end

        def [](name)
            field(name).convert(@raw)
        end

        def raw(name = nil)
            if name.nil?
                @raw
            else
                field(name).extract(@raw)
            end
        end

        def known?
            not part.nil?
        end

        def rectype
            part.rectype if part
        end
    end

    class Record
        attr_reader :rectype

        def initialize(rectype, lines)
            @rectype = rectype
            @lines = lines.inject({}) { |m, l| m[l.part.nr] = l; m }
        end

        def [](k)
            @lines[k]
        end

        def method_missing(name, *args)
            nr, name = @rectype.index(name)
            if nr.nil?
                super
            else
                @lines[nr][name]
            end
        end

        def lines
            @lines.values.sort { |l1, l2| l1.part.nr <=> l2.part.nr }
        end

        def known?
            not rectype.nil?
        end

        def satz
            rectype.satz
        end

        def sparte
            rectype.sparte
        end
    end

    class Reader
        attr_reader :io, :lineno

        # Helper class for the DSL used in Reader.parse
        class Parser
            attr_reader :result

            def initialize(reader, klass, &block)
                @reader = reader
                @result = klass.new
                instance_eval &block
            end

            def one(sym, cond)
                result[sym] = @reader.match!(cond)
            end

            def maybe(sym, cond)
                result[sym] = @reader.match(cond)
            end

            def star(sym, cond)
                result[sym] = []
                while @reader.match?(cond)
                    result[sym] << @reader.getrec
                end
            end

            def object(sym, klass)
                result[sym] = klass.parse(@reader)
            end

            # Parse a sequence of objects of class +klass+ as long
            # as +cond+ matches the current record
            def objects(sym, klass, cond)
                result[sym] = []
                while @reader.match?(cond)
                    result[sym] << klass.parse(@reader)
                end
            end

            # Skip records until we find one that matches +cond+
            def skip_until(cond)
                while ! @reader.match?(cond)
                    @reader.getrec
                end
            end

            def match?(cond)
                @reader.match?(cond)
            end

            def satz?(satz)
                match?(:satz => satz)
            end

            def sparte?(sparte)
                match?(:sparte => sparte)
            end
        end

        def initialize(io)
            @features = [:pad_short_lines]
            if io.is_a?(String)
                @features << :close_at_eof
                @io = File.open(io)
            else
                @io = io
            end
            @lineno = 0
            @records = []
        end

        def feature?(name)
            @features.include?(name)
        end

        def unshift(rec)
            @records.unshift(rec)
        end

        # Return the next record, or nil if there are no more records
        def getrec
            unless @records.empty?
                return @records.shift
            end
            getline unless @line
            return nil if @line.nil?
            lines = [ @line ]
            if rectype = @line.rectype
                loop do
                    getline
                    if @line.nil? || rectype.nil? || rectype != @line.rectype
                        break
                    end
                    lines << @line
                end
            end
            return Record.new(rectype, lines)
        end

        # Return +true+ if the next record matches +cond+ without consuming
        # the record
        def match?(cond)
            rec = getrec
            @records.unshift(rec)
            result = ! rec.nil?
            if result && cond[:satz]
                result = cond_match(rec.satz, cond[:satz])
            end
            if result && cond[:sparte]
                result = cond_match(rec.sparte, cond[:sparte])
            end
            result
        end

        # Return the next record, provided it matches +cond+; otherwise,
        # return nil
        def match(cond)
            getrec if match?(cond)
        end

        # Return the next record, provided it matches +cond+; if it
        # doesn't, raise a ParseError
        def match!(cond)
            rec = match(cond)
            raise ParseError.new(io, lineno, cond) unless rec
            rec
        end

        def parse(klass, &block)
            Parser.new(self, klass, &block).result
        end

        private
        def getline
            if io.closed?
                @line = nil
                return nil
            end
            buf = io.gets
            if buf.nil?
                io.close if feature?(:close_at_eof)
                return nil
            end
            buf.chomp!
            @lineno += 1
            if buf.size != 256
                if feature?(:pad_short_lines)
                    buf += " " * (256 - buf.size)
                else
                    raise RecordSizeError.new(io, lineno), "Expected line with 256 bytes, but read #{buf.size} bytes"
                end
            end
            part = GDV::Format::classify(buf)
            @line = Line.new(buf, part)
        end

        # When +cond+ is an array, check whether +val+ is in +cond+;
        # otherwise check if +cond+ equals +val+
        def cond_match(val, cond)
            if cond.respond_to?(:include?)
                cond.include?(val)
            else
                cond == val
            end
        end
    end

end
