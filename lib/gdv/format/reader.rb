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
    end

    class Reader
        attr_reader :io, :lineno

        def initialize(io)
            @close_at_eof = io.is_a?(String)
            if @close_at_eof
                @io = File.open(io)
            else
                @io = io
            end
            @lineno = 0
        end
        
        def getrec
            line = io.gets
            if line.nil?
                io.close if @close_at_eof
                @close_at_eof = false
                return nil
            end
            line.chomp!
            @lineno += 1
            if line.size != 256 
                raise RecordSizeError.new(io, lineno), "Expected line with 256 bytes, but read #{line.size} bytes"
            end
            part = GDV::Format::classify(line)
            if part.nil?
                raise UnknownRecordError.new(io, lineno), "Could not classify record"
            end
            Record.new(line, part)
        end
    end

end
