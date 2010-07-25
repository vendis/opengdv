# Der spartenspezifische Teil fuer Sparte Leben
module GDV::Model::Sparte
    #
    # Kfz Hauptvertrag
    #
    class Kfz < Base
        attr_reader :haft, :voll, :teil, :unfall, :baustein, :gepaeck

        property :make,  :details, 1, 10
        property :model, :details, 1, 11
        property :price, :addl,    1, 8

        structure do
            one    :details, :satz => DETAILS
            maybe  :addl, :satz => ADDL
            star   :clauses, :satz => GDV::Model::CLAUSES
            star   :rebates, :satz => GDV::Model::REBATES

            object :haft, Haft, Haft.first
            object :voll, Voll, Voll.first
            object :teil, Teil, Teil.first
            object :unfall, Unfall, Unfall.first
            objects :bausteine, Baustein, Baustein.first
            object :gepaeck, Gepaeck, Gepaeck.first

            error(:unexpected) if satz?(SPECIFIC)
        end

        #
        # Teilsparten von Kfz
        #
        class TeilSparte < Base
            def self.sparte
                n = self.name.split("::").last.upcase
                GDV::Model::Sparte.const_get("KFZ_#{n}")
            end

            def self.first
                { :satz => SPECIFIC, :sparte => sparte }
            end

            structure do
                sparte = result.class.sparte
                one    :specific, :satz => SPECIFIC, :sparte => sparte
                maybe  :addl,     :satz => SPEC_ADDL, :sparte => sparte
                star   :clauses,  :satz => GDV::Model::CLAUSES
                star   :rebates,  :satz => GDV::Model::REBATES
                objects :bausteine, Baustein, Baustein.first
            end
        end

        class Haft < TeilSparte
            property :regionalklasse, :specific, 1, 11
            property :sfs,            :specific,  1, 15
            property :beitrag,        :addl, 1, 9
        end

        class Voll < TeilSparte; end

        class Teil < TeilSparte
            property :typkl, :specific, 1, 21
            property :beitrag, :addl, 1, 8
        end

        class Unfall < TeilSparte
            property :deckung1, :specific, 1, 11
            property :invaliditaet, :addl, 1, 9
        end

        class Baustein < TeilSparte; end

        class Gepaeck < TeilSparte; end
    end
end
