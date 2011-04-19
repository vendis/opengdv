module GDV::Format

    class ReaderError < RuntimeError
        attr_reader :path, :lineno, :details
        def initialize(reader, details = "Lesefehler")
            @path = "(input)"
            @path = reader.io.path if reader.io.respond_to?(:path)
            @lineno = reader.lineno
            @details = details
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
            if act = reader.peek
                super(reader, "Satz mit Kennzeichnung #{s} erwartet, aber #{act.rectype} gefunden")
            else
                super(reader, "Satz mit Kennzeichnung #{s} erwartet")
            end
        end
    end

    class Record
        attr_reader :rectype, :lineno

        def initialize(rectype, lines, lineno)
            @rectype = rectype
            @lineno = lineno
            @lines = lines.inject({}) { |m, l| m[l.part.nr] = l; m }
        end

        # @return [Line] the line with +snr+ +k+
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

        # @return [Array<Line>]
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
            # FIXME: For now, we assum ISO-8859-15 encoding of all input
            # files. There are other possibilities, like CP850; when we
            # encounter them, we need a way to set the source character
            # encoding
            @enc = "ISO-8859-15"
        end

        def feature?(name)
            @features.include?(name)
        end

        def unshift(rec)
            @records.unshift(rec)
        end

        # @return [Record] the next record without consuming it
        def peek
            rec = getrec
            unshift(rec)
            rec
        end

        # Read the next record from the input stream
        # @return [Record] the next record
        # @return [nil] if there are no more records
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
                    break if @line.nil? || rectype.nil?
                    break if rectype != @line.rectype
                    break if lines.last.snr >= @line.snr

                    lines << @line
                end
            end
            return Record.new(rectype, lines, @lineno - lines.size)
        end

        # Check if the next record matches the condition +cond+ without
        # consuming the record
        # @return [Boolean] +true+ if the next record
        # matches, +false+ otherwise
        def match?(cond)
            rec = peek
            return false if rec.nil?
            path = rec.rectype.parts.first.path
            cond.keys.all? do |k|
                cond_match(path[k], cond[k])
            end
        end

        # Return the next record, provided it matches +cond+
        # @return [Record] the next record
        # @return [nil] if the next record does not match +cond+ or if
        # there is no next record
        def match(cond)
            getrec if match?(cond)
        end

        # Return the next record, provided it matches +cond+; if it
        # doesn't, raise a MatchError
        # @return [Record] the next record
        # @raise [MatchError] if the next record does not match +cond+
        def match!(cond)
            rec = match(cond)
            raise MatchError.new(self, cond) unless rec
            rec
        end

        # Parse records according to the grammar in +klass.grammar+
        def parse(klass)
            Parser.new(self, klass).result
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
                    @line = nil
                    io.close if feature?(:close_at_eof)
                    return nil
                end
                buf.chomp!
                @lineno += 1
                if buf.size != 256
                    if feature?(:pad_short_lines) && buf.size < 256
                        buf += " " * (256 - buf.size)
                    else
                        raise RecordSizeError.new(self), "Expected line with 256 bytes, but read #{buf.size} bytes"
                    end
                end
                # FIXME: We silently skip anything we don't understand
                part = GDV::Format::Classifier.classify(buf)
                @unknown += 1 if part.nil?
                if part.nil?
                    # Log message only makes sense for records 0220.030
                    GDV::logger.info "#{lineno}:unknown record:#{buf[0,4]}.#{buf[10,3]} skenn='#{buf[255,1]}' snr='#{buf[249,1]}'"
                end
            end while part.nil?
            @line = Line.new(buf, part, @enc)
        end

        # When +cond+ is an array, check whether +val+ is in +cond+;
        # otherwise check if +cond+ equals +val+
        def cond_match(val, cond)
            return cond.nil? && val.nil? if cond.nil? || val.nil?
            if cond.respond_to?(:include?)
                cond.include?(val)
            else
                cond == val
            end
        end
    end

end
