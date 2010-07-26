# The partner portion of a contract
module GDV::Model
    class Partner < Base
        attr_reader :address, :signatures, :clauses, :rebates

        property :anrede,   :address, 1, 8
        property :nachname, :address, 1, 9
        property :vorname,  :address, 1, 11
        property :kdnr_vu,  :address, 2, 8

        property :geburtsort, :address, 4, 9

        first :satz => ADDRESS_TEIL

        structure do
            one  :address,    :satz => ADDRESS_TEIL
            star :signatures, :satz => SIGNATURES
            star :clauses,    :satz => CLAUSES
            star :rebates,    :satz => REBATES
        end
    end
end
