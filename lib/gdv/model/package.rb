# Ein Datenpaket, d.h. der Teil einer Uebertragung, der mit einem Vorsatz beginnt und einem Nachsatz endet
module GDV::Model
    class Package < Base
        attr_reader :vorsatz, :nachsatz, :contracts

        property :vunr, :vorsatz, 1, 2

        structure do
            one :vorsatz, :satz => VORSATZ
            objects :contracts, Contract, :satz => ADDRESS_TEIL
            one :nachsatz, :satz => NACHSATZ
        end
    end
end
