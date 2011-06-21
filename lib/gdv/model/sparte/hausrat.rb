# Der spartenspezifische Teil fuer Sparte 130 Hausrat
module GDV::Model::Sparte
  class Hausrat < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => HR
        maybe   :addl, :sid => SPEC_ADDL, :sparte => HR
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => HR
      maybe   :addl,    :sid => ADDL, :sparte => HR
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
