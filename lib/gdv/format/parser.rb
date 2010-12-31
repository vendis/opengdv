module GDV::Format
    # Helper class for the DSL used in Reader.parse
    class Parser
        attr_reader :result

        def initialize(reader, klass, &block)
            @reader = reader
            @result = klass.new
            klass.grammar.run(self)
        end

        def one(sym, opts)
            result[sym] = @reader.match!(opts)
        end

        def maybe(sym, opts)
            result[sym] = @reader.match(opts)
        end

        def star(sym, opts)
            result[sym] = []
            while @reader.match?(opts)
                result[sym] << @reader.getrec
            end
        end

        def object(sym, opts)
            klass = opts[:class]
            if @reader.match?(klass.first)
                result[sym] = klass.parse(@reader)
            end
        end

        # Parse a sequence of objects of class +klass+ as long
        # as +cond+ matches the current record
        def objects(sym, opts)
            klass = opts[:class]
            result[sym] = []
            while @reader.match?(klass.first)
                result[sym] << klass.parse(@reader)
            end
        end

        # Skip records until we find one that matches +cond+
        def skip_until(dummy, cond)
            while ! @reader.match?(cond)
                break unless @reader.getrec
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

        def error(dummy, opts)
            return unless opts[:test].call(self)
            msg = opts[:message]
            if msg == :unexpected
                rec = @reader.getrec
                @reader.unshift(rec)
                msg = "unerwarteter Satz #{rec.rectype}"
            end
            raise ParseError.new(@reader, msg)
        end
    end

end
