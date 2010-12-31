# Ein Datenpaket, d.h. der Teil einer Uebertragung, der mit einem Vorsatz beginnt und einem Nachsatz endet
module GDV::Model
    class Package < Base
        attr_accessor :filename

        grammar do
            one :vorsatz, :satz => VORSATZ
            objects :contracts, Contract
            one :nachsatz, :satz => NACHSATZ
        end

        property :vunr, :vorsatz, 1, 2
        property :created_from_until, :vorsatz, 1, 5

        def created_from
            GDV::Format.parse_date(created_from_until_raw[0, 8])
        end

        def created_until
            GDV::Format.parse_date(created_from_until_raw[8, 8])
        end
    end
end
