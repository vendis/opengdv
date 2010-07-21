# A contract, i.e. everything between the Vorsatz and Nachsatz
class GDV::Contract
    attr_reader :address

    def initialize(address)
        @address = address
    end
end
