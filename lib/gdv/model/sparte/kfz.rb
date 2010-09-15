# Der spartenspezifische Teil fuer Sparte KfZ
module GDV::Model::Sparte
    #
    # Kfz Hauptvertrag
    #
    class Kfz < Base
        attr_reader :haft, :voll, :teil, :unfall, :baustein, :gepaeck

        property :make,  :details, 1, 10
        property :model, :details, 1, 11
        property :price, :addl,    1, 8
        property :we,    :details, 1, 21

        structure do
            one    :details, :satz => DETAILS
            maybe  :addl, :satz => ADDL
            star   :clauses, :satz => GDV::Model::CLAUSES
            star   :rebates, :satz => GDV::Model::REBATES

            object :haft, Haft
            object :voll, Voll
            object :teil, Teil
            object :unfall, Unfall
            objects :bausteine, Baustein
            object :gepaeck, Gepaeck

            error(:unexpected) if satz?(SPECIFIC)
        end

        first :satz => DETAILS, :sparte => KFZ

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

            attr_reader :specific

            structure do
                sparte = result.class.sparte
                one    :specific, :satz => SPECIFIC, :sparte => sparte
                maybe  :addl,     :satz => SPEC_ADDL, :sparte => sparte
                star   :clauses,  :satz => GDV::Model::CLAUSES
                star   :rebates,  :satz => GDV::Model::REBATES
                objects :bausteine, Baustein
            end
        end

        class Haft < TeilSparte
            property :regionalklasse, :specific, 1, 11
            property :sfs,            :specific,  1, 15

            def beitrag
                return addl[1][9] if addl
                specific[1][17]
            end
        end

        class Voll < TeilSparte
            property :beitrag,        :specific, 1, 16
        end

        class Teil < TeilSparte
            property :typkl, :specific, 1, 21
            property :beitrag, :addl, 1, 8
            def beitrag
                return addl[1][8] if addl
                specific[1][13]
            end
        end

        class Unfall < TeilSparte
            property :deckung1, :specific, 1, 11
            property :invaliditaet, :addl, 1, 9
            property :beitrag, :specific, 1, 25
        end

        class Baustein < TeilSparte; end

        class Gepaeck < TeilSparte; end
    end
end
