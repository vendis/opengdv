require 'stringio'

module GDV::Format

    class RecIndex
        attr_reader :field, :children, :parts, :parent

        def initialize(parent, field, part)
            debug "node #{pf(field)} : #{part}"
            @parent = parent
            @field = field
            @children = {}
            @parts = {}
            field.values.each { |v| @parts[v] = part }
        end


        def insert(part)
            debug "Insert #{part} for #{pf(field)}"
            f = part.field_at(field.pos, field.len)
            if f.nil? || ! f.const?
                part.emit
                raise FormatError, "Incompatible fields #{pf(f)} #{field} for #{part}"
            end
            debug "  with values |#{f.values.join('|')}|"
            f.values.each do |value|
                debug "Value: #{value} Child: #{children.key?(value)} Part: #{parts.key?(value)} "
                if children.key?(value)
                    debug "Insert into child #{value}"
                    children[value].insert(part)
                elsif parts.key?(value)
                    # Need to split and find another field to
                    # discriminate by
                    old_part = parts[value]
                    debug "Splitting #{old_part} at #{value}"
                    key_fields = unused_fields(old_part, part)
                    if key_fields.empty?
                        raise_no_key_field_error(old_part, part)
                    end
                    new_field = key_fields[0]
                    debug "new_field: #{pf(new_field)} at #{value}"
                    children[value] = RecIndex.new(self, new_field,
                                                    old_part)
                    parts.delete(value)
                    children[value].insert(part)
                    msg = ".." * depth
                    debug "new_field: #{pf(new_field)} at #{value} #{msg}"
                else
                    debug "Adding part #{pf(f)}"
                    parts[value] = part
                end
            end
        end

        # Return the part that describes this record
        def classify(record)
            v = field.extract(record)
            ind = "  " * depth
            log =  "Match #{pf(field)} against '#{v}': "
            if parts.key?(v)
                debug "#{log} <= #{parts[v]}"
                return parts[v]
            elsif children.key?(v)
                debug "#{log} child"
                return children[v].classify(record)
            else
                debug "#{log} unknown"
                return nil
            end
        end

        def finalize(path = {})
            parts.each_key do |k|
                parts[k].path = { field.name => k }.merge!(path) unless parts[k].path
            end
            children.each do |v, c|
                c.finalize({ field.name => v }.merge!(path))
            end
        end

        def find_part(path)
            parts[path[field.name]] ||
                children[path[field.name]].find_part(path)
        end

        def print(sio=nil)
            sio = StringIO.new unless sio
            sio.puts "#{ind}#{field.name}@#{field.pos}+#{field.len}"
            parts.keys.sort.each do |k|
                sio.puts "#{ind}  #{k} -> #{parts[k]}"
            end
            children.sort.each do |v, c|
                sio.puts "#{ind}  #{v} ==>"
                c.print(sio)
            end
            return sio.string
        end

        def depth
            p = self.parent
            depth = 0
            while p
                depth += 1
                p = p.parent
            end
            return depth
        end

        def leaves
            result = children.values.inject([]) { |r, c| r + c.leaves }
            result + parts.values
        end

        def height
            if children.empty?
                1
            else
                children.values.collect{ |c| c.height }.max + 1
            end
        end

        private
        def raise_no_key_field_error(old_part, part)
            msg = %{No fields left to add part #{part}
#{old_part} #{old_part.key_fields.collect{ |f| pf(f) }.join(" ")}
#{part} #{part.key_fields.collect{ |f| pf(f) }.join(" ")}
}
            raise FormatError, msg
        end

        def ind
            "  " * depth
        end

        def pf(field)
            return "no field" unless field
            const = ""
            const = "=#{field.values.join(",")}" if field.const?
            "#{field.name}@#{field.pos}+#{field.len}#{const}"
        end

        def unused_fields(part1, part2)
            key_fields = part1.key_fields.clone
            p = self
            while p
                f = part1.field_at(p.field.pos, p.field.len)
                key_fields.delete(f)
                p = p.parent
            end
            key_fields = key_fields.select do |kf|
                part2.field_at(kf.pos, kf.len)
            end
            key_fields
        end

        private
        def debug(msg)
            # FIXME: debug output from this module is too chatty
            # GDV::logger.debug msg
        end
    end
end
