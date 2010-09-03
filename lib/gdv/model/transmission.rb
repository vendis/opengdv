# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
module GDV::Model
    class Transmission
        attr_reader :packages

        def initialize(filename)
            reader = GDV::Format::Reader.new(filename)
            @packages = []
            while reader.match?(VORSATZ)
                @packages << Package::parse(reader)
                @packages.last.filename = filename
            end
        end
    end
end
