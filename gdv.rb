module GDV

    module Model

        class Satzart
            attr_reader :satz, :sparte, :parts
            def initialize(satz, sparte, parts)
                @satz = satz
                @sparte = sparte
                @parts = parts
            end

            def inspect
                "satz = #{satz}\nsparte = #{sparte}\n parts = #{parts.inspect}"
            end
        end
        
        class Part
            attr_reader :nr, :fields
            def initialize(nr, fields)
                @nr = nr
                @fields = fields
            end
            
            def inspect
                "  nr = #{nr}\n  fields = #{fields.inspect}"
            end
        end
        
        class Field
            attr_reader :nr, :name, :pos, :len, :type, :value, :label
            def initialize(nr, name, pos, len, type, value, label)
                @nr = nr
                @name = name
                @pos = pos
                @len = len
                @type = type
                @value = value
                @label = label
            end

            def inspect
                n = ''
                n = ":#{name}" if name
                "<Field[#{nr}]#{type}:#{pos}+#{len}#{n}>\n"
            end
        end

        class Path
            attr_accessor :satz, :teil, :nr, :sparte
        end

        class Typ
            attr_accessor :name, :paths, :values
        end

    end
end


