# The partner portion of a contract
class GDV::Model::Partner < GDV::Model::Base
    attr_reader :address, :signatures, :clauses, :rebates

    # Partner := 0100 0342* 0350* 0390*
    def self.parse(reader)
        reader.parse(self) do
            one :address, :satz => GDV::Format::ADDRESS_TEIL
            star :signatures, :satz => GDV::Format::SIGNATURES
            star :clauses, :satz => GDV::Format::CLAUSES
            star :rebates, :satz => GDV::Format::REBATES
        end
    end
end
