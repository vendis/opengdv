module GDV::Model::Sparte
    class Base < GDV::Model::Base
        attr_reader :details, :addl, :clauses, :rebates

        def sparte?(sp)
            details.rectype.sparte == sp
        end
    end
end
