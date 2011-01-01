# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
module GDV::Model
    class Transmission
        attr_reader :packages, :contracts_count, :unique_contracts_count

        def initialize(filename)
            reader = GDV::Format::Reader.new(filename)
            @packages = []
            reader.unshift reader.match!(:sid => VORSATZ)
            @contracts_count = 0
            while reader.match?(:sid => VORSATZ)
                @packages << Package::parse(reader)
                @packages.last.filename = filename
                @contracts_count += @packages.last.contracts.size
            end
            index = Hash.new(0)
            self.each_contract { |p, c| index["#{c.vunr}##{c.vsnr}"] += 1 }
            @unique_contracts_count = index.keys.size
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
