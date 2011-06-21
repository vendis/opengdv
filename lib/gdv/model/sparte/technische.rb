# Der spartenspezifische Teil fuer Sparte 170 Technische
module GDV::Model::Sparte
  class Technische < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => TECHN
        maybe   :addl, :sid => SPEC_ADDL, :sparte => TECHN
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => TECHN
      maybe   :addl,    :sid => ADDL, :sparte => TECHN
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
