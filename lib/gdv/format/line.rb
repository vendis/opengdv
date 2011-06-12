module GDV::Format
    # An individual line in a file. Combines the actual string from the
    # file with the underlying {Part} describing the field layout
    class Line
        # @return [Part] the part matching the line
        attr_reader :part

        # Create a new line, based on the 256 byte string +raw+ that will
        # be split into fields according to +part+
        def initialize(raw, part, enc = nil)
            @raw = raw
            @part = part
            @enc = enc
        end

        # @return [Field] the field +name+ from +part+
        def field(name)
            @part[name]
        end

        # Return the converted value for field +name+ in this line
        def [](name)
            field(name).convert(@raw, @enc)
        end

        # Return the raw value for field +name+ in this line, or the entire
        # line if +name+ is +nil+
        # @return [String] the raw field value
        def raw(name = nil)
            if name.nil?
                @raw
            else
                field(name).extract(@raw)
            end
        end

        # Return the original mapped value for field +name+
        def orig_mapped(name)
          field(name).orig_mapped(@raw)
        end

        # Return the +snr+ (Satznummer) for this line
        def snr
            part.nr
        end

        # Return the +Rectype+ to which the +part+ belongs
        def rectype
            part.rectype if part
        end
    end
end
