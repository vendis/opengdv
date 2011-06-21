# Der spartenspezifische Teil fuer Sparte 000 Allgemein
module GDV::Model::Sparte
  class Allgemein < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => ALLGEMEIN
        maybe   :addl, :sid => SPEC_ADDL, :sparte => ALLGEMEIN
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => ALLGEMEIN
      maybe   :addl,    :sid => ADDL, :sparte => ALLGEMEIN
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
