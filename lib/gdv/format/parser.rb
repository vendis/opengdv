module GDV::Format
    # Helper class for the DSL used in Reader.parse
    class Parser
        attr_reader :result

        def initialize(reader, klass, &block)
            @reader = reader
            @result = klass.new
            unless block_given?
                raise ParseError.new(@reader, "No structure defined for #{klass}")
            end
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

        def peek
            @reader.peek
        end

        def error(msg = nil)
            if msg == :unexpected
                rec = @reader.getrec
                @reader.unshift(rec)
                msg = "unerwarteter Satz #{rec.rectype}"
            end
            raise ParseError.new(@reader, msg)
        end
    end

end
