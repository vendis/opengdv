# Der spartenspezifische Teil fuer Sparte Leben
module GDV::Model::Sparte
    class Kfz < Base
        property :make,  :details, 1, 10
        property :model, :details, 1, 11
        property :price, :addl,    1, 8

        structure do
            one    :details, :satz => DETAILS
            maybe  :addl, :satz => ADDL
            star   :clauses, :satz => GDV::Model::CLAUSES
            star   :rebates, :satz => GDV::Model::REBATES
        end
    end
end
