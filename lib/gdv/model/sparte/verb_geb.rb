# Der spartenspezifische Teil fuer Sparte 140 Verbundene Gebaeude
module GDV::Model::Sparte
  class VerbGeb < Base

    class Risiko < Base
      grammar do
        one     :data, :sid => SPECIFIC, :sparte => VERB_GEB
        maybe   :addl, :sid => SPEC_ADDL, :sparte => VERB_GEB
        star    :clauses,  :sid => GDV::Model::CLAUSES
        star    :rebates,  :sid => GDV::Model::REBATES
      end
    end

    grammar do
      one     :details, :sid => DETAILS, :sparte => VERB_GEB
      maybe   :addl,    :sid => ADDL, :sparte => VERB_GEB
      star    :clauses,  :sid => GDV::Model::CLAUSES
      star    :rebates,  :sid => GDV::Model::REBATES
      objects :risks, Risiko
    end
  end
end
