module GDV::Format

    class ReaderError < RuntimeError
        attr_reader :path, :lineno
        def initialize(io, lineno)
            @path = "(input)"
            @path = io.path if io.respond_to?(:path)
            @lineno = lineno
        end
    end

    class RecordSizeError < ReaderError
    end

    class UnknownRecordError < ReaderError
    end

    class Line
        attr_reader :raw, :part

        def initialize(raw, part)
            @raw = raw
            @part = part
        end

        def field(name)
            @part[name]
        end

        def [](name)
            field(name).extract(@raw)
        end

        def known?
            not part.nil?
        end

        def rectype
            @part.rectype
        end
    end

    class Record
        attr_reader :rectype

        def initialize(rectype, lines)
            @rectype = rectype
            @lines = lines.inject({}) { |m, l| m[l.part.nr] = l; m }
        end

        def [](nr)
            @lines[nr]
        end

        def lines
            @lines.values.sort { |l1, l2| l1.part.nr <=> l2.part.nr }
        end

        def known?
            not rectype.nil?
        end
    end

    class Reader
        attr_reader :io, :lineno

        def initialize(io)
            @features = [:pad_short_lines]
            if io.is_a?(String)
                @features << :close_at_eof
                @io = File.open(io)
            else
                @io = io
            end
            @lineno = 0
        end

        def feature?(name)
            @features.include?(name)
        end

        def getrec
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

    end

end
