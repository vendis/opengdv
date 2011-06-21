# Der spartenspezifische Teil fuer Sparte 040 Haftpflicht
module GDV::Model::Sparte
  class Haftpflicht < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => HAFTPFLICHT
        maybe   :addl, :sid => SPEC_ADDL, :sparte => HAFTPFLICHT
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => HAFTPFLICHT
      maybe   :addl,    :sid => ADDL, :sparte => HAFTPFLICHT
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
