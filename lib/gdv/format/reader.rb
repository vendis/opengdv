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
    
    class Record
        attr_reader :raw, :part

        def initialize(raw, part)
            @raw = raw
            @part = part
        end

        def known?
            not part.nil?
        end
    end

    class Reader
        attr_reader :io, :lineno, :line

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
            @line = io.gets
            if line.nil?
                io.close if feature?(:close_at_eof)
                return nil
            end
            @line.chomp!
            @lineno += 1
            if line.size != 256 
                if feature?(:pad_short_lines)
                    @line += " " * (256 - line.size)
                else
                    raise RecordSizeError.new(io, lineno), "Expected line with 256 bytes, but read #{line.size} bytes"
                end
            end
            if line.nil?
                raise RuntimeError, "Line disappeared #{lineno}"
            end
            part = GDV::Format::classify(line)
            Record.new(line, part)
        end

    end

end
