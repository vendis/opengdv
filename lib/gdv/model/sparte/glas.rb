# Der spartenspezifische Teil fuer Sparte 110 Glas
module GDV::Model::Sparte
  class Glas < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => GLAS
        maybe   :addl, :sid => SPEC_ADDL, :sparte => GLAS
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => GLAS
      maybe   :addl,    :sid => ADDL, :sparte => GLAS
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
