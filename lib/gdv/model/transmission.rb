# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
module GDV::Model
    class Transmission
        attr_reader :packages, :contracts_count

        def initialize(filename)
            reader = GDV::Format::Reader.new(filename)
            @packages = []
            reader.unshift reader.match!(:satz => VORSATZ)
            @contracts_count = 0
            while reader.match?(:satz => VORSATZ)
                @packages << Package::parse(reader)
                @packages.last.filename = filename
                @contracts_count += @packages.last.contracts.size
            end
        end

        # Calls +block+ once for each contract in this transmission,
        # passing the package to which the contract belongs and the
        # contract.
        def each_contract(&block)
            @packages.each do |pkg|
                pkg.contracts.each do |contract|
                    yield(pkg, contract)
                end
            end
        end
    end
end
