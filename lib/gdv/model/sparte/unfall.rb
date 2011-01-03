# Der spartenspezifische Teil fuer Sparte 030 Unfall
module GDV::Model::Sparte
    class UnfallVp < Base
        grammar do
            one     :data, :sid => SPECIFIC, :sparte => UNFALL
            maybe   :addl, :sid => SPEC_ADDL, :sparte => UNFALL
            star    :benefits, :sid => "0230", :sparte => UNFALL
            star    :clauses,  :sid => GDV::Model::CLAUSES
            star    :rebates,  :sid => GDV::Model::REBATES
        end

        property :nachname,  :data, 1, 12
        property :vorname,   :data, 1, 13
        property :birthdate, :data, 1, 14
    end

    class Unfall < Base
        grammar do
            one     :details, :sid => DETAILS, :sparte => UNFALL
            star    :clauses,  :sid => GDV::Model::CLAUSES
            star    :rebates,  :sid => GDV::Model::REBATES
            objects :vps, UnfallVp
        end

        property    :tarif, :details, 1, 30
    end
end
