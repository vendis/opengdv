# Der spartenspezifische Teil fuer Sparte 080 Feuer
module GDV::Model::Sparte
  class Feuer < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => FEUER
        maybe   :addl, :sid => SPEC_ADDL, :sparte => FEUER
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => FEUER
      maybe   :addl,    :sid => ADDL, :sparte => FEUER
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
