# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
module GDV::Model
    class Transmission < Base
        attr_reader :vorsatz, :nachsatz, :contracts

        property :vunr, :vorsatz, 1, 2

        structure do
            one :vorsatz, :satz => VORSATZ
            objects :contracts, Contract, :satz => ADDRESS_TEIL
            one :nachsatz, :satz => NACHSATZ
        end
    end
end
