# A contract, i.e. everything between the Vorsatz and Nachsatz
class GDV::Contract
    attr_reader :partner

    def self.parse(reader)
        reader.parse(GDV::Contract) do
            object :partner, GDV::Partner
            skip_until :satz => [GDV::Format::ADDRESS_TEIL,
                                 GDV::Format::NACHSATZ]
        end
    end
end
