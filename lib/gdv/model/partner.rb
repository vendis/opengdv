# The partner portion of a contract
class GDV::Model::Partner < GDV::Model::Base
    attr_reader :address, :signatures, :clauses, :rebates

    # Partner := 0100 0342* 0350* 0390*
    def self.parse(reader)
        reader.parse(self) do
            one :address, :satz => ADDRESS_TEIL
            star :signatures, :satz => SIGNATURES
            star :clauses, :satz => CLAUSES
            star :rebates, :satz => REBATES
        end
    end
end
