# Der spartenspezifische Teil fuer Sparte KfZ
module GDV::Model::Sparte
    #
    # Kfz Hauptvertrag
    #
    class Kfz < Base
        #
        # Teilsparten von Kfz
        #
        class TeilSparte < Base
            def self.sparte
                n = self.name.split("::").last.upcase
                GDV::Model::Sparte.const_get("KFZ_#{n}")
            end

            def self.first
                { :sid => SPECIFIC, :sparte => sparte }
            end

            def self.inherited(subclass)
                subclass.grammar do
                    one    :specific, :sid => SPECIFIC,
                           :sparte => subclass.sparte
                    maybe  :addl,     :sid => SPEC_ADDL,
                           :sparte => subclass.sparte
                    star   :clauses,  :sid => GDV::Model::CLAUSES
                    star   :rebates,  :sid => GDV::Model::REBATES
                    objects :bausteine, GDV::Model::Sparte::Kfz::Baustein
                end
            end
        end

        class Baustein < TeilSparte; end

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

        class Gepaeck < TeilSparte; end

        #
        # Main Kfz class
        #

        grammar do
            one    :details, :sid => DETAILS
            maybe  :addl, :sid => ADDL
            star   :clauses, :sid => GDV::Model::CLAUSES
            star   :rebates, :sid => GDV::Model::REBATES

            object :haft, Haft
            object :voll, Voll
            object :teil, Teil
            object :unfall, Unfall
            objects :bausteine, Baustein
            object :gepaeck, Gepaeck

            error(:unexpected) { |parser| parser.satz?(SPECIFIC) }
        end

        first :sid => DETAILS, :sparte => KFZ

        property :wagnis, :details, 1, 8
        property :staerke, :details, 1, 9
        property :make,  :details, 1, 10
        property :model, :details, 1, 11
        property :hsn,   :details, 1, 12
        property :tsn,   :details, 1, 13
        property :vin,   :details, 1, 14
        property :kennz, :details, 1, 15
        property :erstzul_on, :details, 1, 16
        property :neupreis, :details, 1, 17
        property :we,    :details, 1, 21

        property :fz_art, :details, 2, 10
        property :erstzul_vn_on, :details, 2, 14
        property :fahrleistung,  :details, 2, 20
        property :garage, :details, 2, 21
        property :nutzungsart, :details, 2, 22
        property :staerke_einheit, :details, 2, 35

        property :price, :addl,    1, 8

    end
end
