# The partner portion of a contract
module GDV::Model
    class Partner < Base
        grammar do
            one  :address,    :sid => ADDRESS_TEIL
            star :signatures, :sid => SIGNATURES
            star :clauses,    :sid => CLAUSES
            star :rebates,    :sid => REBATES
        end
        first :sid => ADDRESS_TEIL

        property :anrede,   :address, 1, 8
        property :nachname, :address, 1, 9
        property :vorname,  :address, 1, 11
        property :land,     :address, 1, 13
        property :plz,      :address, 1, 14
        property :ort,      :address, 1, 15
        property :strasse,  :address, 1, 16
        property :postfach, :address, 1, 17
        property :birthdate,:address, 1, 18
        property :geschlecht, :address, 1, 25

        property :kdnr_vu,  :address, 2, 8

        property :geburtsort, :address, 4, 9
    end
end
