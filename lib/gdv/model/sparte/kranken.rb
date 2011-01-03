# Der spartenspezifische Teil fuer Sparte 020 Kranken
module GDV::Model::Sparte

    # Kranken - Tarifdaten
    class KrankenRate < Base
        grammar do
            one   :general, :sid => SPECIFIC, :sparte => KRANKEN, :skenn => "2"
            maybe :special, :sid => SPECIFIC, :sparte => KRANKEN, :skenn => "3"
            star   :clauses, :sid => GDV::Model::CLAUSES
            star   :rebates, :sid => GDV::Model::REBATES
        end

        property :benefit_begin,    :general, 1, 15
        property :benefit_duration, :general, 1, 16
    end

    # Kranken - Personenspezifische Daten 020
    class KrankenVp < Base
        grammar do
            one    :data, :sid => SPECIFIC, :sparte => KRANKEN, :skenn => "1"
            star   :clauses, :sid => GDV::Model::CLAUSES
            star   :rebates, :sid => GDV::Model::REBATES
            objects :rates, KrankenRate
        end

        property :nachname,  :data, 1, 13
        property :vorname,   :data, 1, 14
        property :birthdate, :data, 1, 16
    end

    # Kranken - 0210.020
    class Kranken < Base
        grammar do
            one     :details,  :sid => DETAILS, :sparte => KRANKEN
            star    :clauses,  :sid => GDV::Model::CLAUSES
            star    :rebates,  :sid => GDV::Model::REBATES
            objects :vps, KrankenVp
        end
    end
end
