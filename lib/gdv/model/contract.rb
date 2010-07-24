# A contract, i.e. everything between the Vorsatz and Nachsatz
class GDV::Model::Contract
    attr_reader :partner, :general, :signatures, :clauses, :rebates

    def self.parse(reader)
        reader.parse(self) do
            object :partner, GDV::Model::Partner
            one    :general, :satz => GDV::Format::GENERAL_CONTRACT
            star   :signatures, :satz => GDV::Format::SIGNATURES
            star   :clauses, :satz => GDV::Format::CLAUSES
            star   :rebates, :satz => GDV::Format::REBATES
            skip_until :satz => [GDV::Format::ADDRESS_TEIL,
                                 GDV::Format::NACHSATZ]
        end
    end
end
