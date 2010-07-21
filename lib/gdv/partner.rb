# The partner portion of a contract
class GDV::Partner
    attr_reader :address, :signatures, :clauses, :rebates

    # Partner := 0100 0342* 0350* 0390*
    def self.parse(reader)
        reader.parse(GDV::Partner) do
            one :address, :satz => GDV::Format::ADDRESS_TEIL
            star :signatures, :satz => GDV::Format::SIGNATURES
            star :clauses, :satz => GDV::Format::CLAUSES
            star :rebates, :satz => GDV::Format::REBATES
        end
    end
end
