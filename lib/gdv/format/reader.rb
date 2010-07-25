module GDV::Format

    class ReaderError < RuntimeError
        attr_reader :path, :lineno
        def initialize(reader, details = nil)
            @path = "(input)"
            @path = reader.io.path if reader.io.respond_to?(:path)
            @lineno = reader.lineno
            details = "Lesefehler" unless details
            super("#{path}:#{lineno}:#{details}")
        end
    end

    class RecordSizeError < ReaderError
    end

    class UnknownRecordError < ReaderError
    end

    class ParseError < ReaderError
        def initialize(reader, details = nil)
            super
        end
    end

    class MatchError < ReaderError
        def initialize(reader, cond = {})
            s = cond.keys.collect { |k| "#{k} = #{cond[k]}" }.join(" und ")
            super(reader, "Satz mit Kennzeichnung #{s} erwartet")
        end
    end

    class Record
        attr_reader :rectype

        def initialize(rectype, lines)
            @rectype = rectype
            @lines = lines.inject({}) { |m, l| m[l.part.nr] = l; m }
        end

        def [](k)
            @lines[k] || @rectype.parts[k-1].default
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
        attr_reader :io, :lineno, :unknown

        def initialize(io)
            @features = [:pad_short_lines]
            if io.is_a?(String)
                @features << :close_at_eof
                @io = File.open(io)
            else
                @io = io
            end
            @lineno = 0
            @unknown = 0
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
        # doesn't, raise a MatchError
        def match!(cond)
            rec = match(cond)
            raise MatchError.new(self, cond) unless rec
            rec
        end

        def parse(klass, &block)
            Parser.new(self, klass, &block).result
        end

        private
        def getline
            begin
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
                # FIXME: We silently skip anything we don't understand
                part = GDV::Format::classify(buf)
                @unknown += 1 if part.nil?
            end while part.nil?
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
