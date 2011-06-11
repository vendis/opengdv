require 'singleton'

module GDV::Format
    # Classify records (lines from a file) as a record type
    class Classifier
        include Singleton

        attr_reader :rectypes, :maps, :recindex

        def initialize
            # Load value map overrides
            File.open(File.join(GDV::format_path, 'value_maps.yaml')) do |f|
                @override_maps = YAML.load(f)
            end

            File.open(File.join(GDV::format_path, 'rectypes.txt')) do |f|
                load_rectypes(f)
            end

            # Build the index for classifying records
            if @recindex.nil?
                parts = @rectypes.inject([]) { |l, rt| l + rt.parts }
                p = parts.shift
                @recindex = RecIndex.new(nil, p[:sid], p)
                parts.each do |p|
                    @recindex.insert(p)
                end
                @recindex.finalize
            end
        end

        def classify(record)
            @recindex.classify(record)
        end

        def self.classify(record)
            instance.classify(record)
        end

        def self.maps
            instance.maps
        end

        def self.rectypes
            instance.rectypes
        end

        def self.find_part(path)
            instance.recindex.find_part(path)
        end

        private
        def load_rectypes(file)
            fields = []
            parts = []
            @rectypes = []
            map = {}
            @maps = {}
            cnt = 0
            begin
                file.each_line do |line|
                    cnt += 1
                    line.chomp!
                    a = line.split(/:/)
                    typ = a.first
                    case typ
                    when "K":
                            @rectypes << RecType::parse(parts, a)
                        parts = []
                    when "T":
                            parts << Part::parse(fields, a)
                        fields = []
                    when "F":
                            fields << Field::parse(a, @maps)
                        # Types with fixed values
                    when "V":
                            map[a[1]] = a[2]
                    when "M":
                            t = a[1].to_sym
                        if @maps[t]
                            raise FormatError, "Duplicate value map #{t}"
                        end
                        @maps[t] = ValueMap.new(a[2], map, @override_maps[t])
                        map = {}
                    end
                end
            rescue FormatError => e
                puts "#{cnt}:#{e}"
                raise e
            end
            @rectypes.each { |rt| rt.finalize }
        end
    end
end
