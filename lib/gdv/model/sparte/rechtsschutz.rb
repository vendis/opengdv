# Der spartenspezifische Teil fuer Sparte 070 Rechtsschutz
module GDV::Model::Sparte
  class Rechtsschutz < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => RS
        maybe   :addl, :sid => SPEC_ADDL, :sparte => RS
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end

      property :nachname,  :data, 1, 12
      property :vorname,   :data, 1, 13
      property :birthdate, :data, 1, 14
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => RS
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
