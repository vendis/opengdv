# An individual line in a file. Combines the actual string from the file
# with the underlying +Part+ describing the field layout
module GDV::Format
    class Line
        attr_reader :part

        # Create a new line, based on the 256 byte string +raw+ that will
        # be split into fields according to +part+
        def initialize(raw, part)
            @raw = raw
            @part = part
        end

        # Return the field +name+ from +part+
        def field(name)
            @part[name]
        end

        # Return the converted value for field +name+ in this line
        def [](name)
            field(name).convert(@raw)
        end

        # Return the raw value for field +name+ in this line
        def raw(name = nil)
            if name.nil?
                @raw
            else
                field(name).extract(@raw)
            end
        end

        # Return +true+ if +part+ is set
        def known?
            not part.nil?
        end

        # Return the +Rectype+ to which the +part+ belongs
        def rectype
            part.rectype if part
        end
    end
end
