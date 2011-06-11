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
            property :begin_on,        :specific, 1, 8
            property :regionalklasse,  :specific, 1, 11
            property :deckungsart,     :specific, 1, 12
            property :deckungssumme,   :specific, 1, 13
            property :rabattgrundjahr, :specific, 1, 14
            property :sfs,             :specific, 1, 15
            property :beitragssatz,    :specific, 1, 16
            property :beitrag,         :specific, 1, 17
            property :schutzbrief,     :specific, 1, 28
            property :typkl,           :specific, 1, 31

            def beitrag
                return addl[1][9] if addl
                specific[1][17]
            end
        end

        class Voll < TeilSparte
            property :begin_on,        :specific, 1,  8
            property :excluded_on,     :specific, 1,  9
            property :changed_on,      :specific, 1, 10
            property :regionalklasse,  :specific, 1, 11
            property :deckungsart,     :specific, 1, 12
            property :rabattgrundjahr, :specific, 1, 13
            property :sfs,             :specific, 1, 14
            property :beitragssatz,    :specific, 1, 15
            property :beitrag,         :specific, 1, 16
            property :claims_prev_year, :specific, 1, 24
            property :typkl,           :specific, 1, 25
            property :free_deductible,      :specific, 1, 26
            property :free_deductible_tk,   :specific, 1, 30
            property :gap_deckung,     :specific, 1, 36
        end

        class Teil < TeilSparte
            property :begin_on,        :specific, 1,  8
            property :excluded_on,     :specific, 1,  9
            property :changed_on,      :specific, 1, 10
            property :regionalklasse,  :specific, 1, 11
            property :deckungsart,     :specific, 1, 12
            property :flottenrabatt,   :specific, 1, 18
            property :typkl,           :specific, 1, 21
            property :free_deductible, :specific, 1, 22
            property :gap_deckung,     :sepcific, 1, 30
            property :deductible,      :specific, 2, 11

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
        property :mehrwert, :details, 1, 18
        property :flotte, :details, 1, 20
        property :we,    :details, 1, 21
        property :sonderbed, :details, 1, 24
        property :saisonkennz, :details, 1, 33

        property :fz_art, :details, 2, 10
        property :kennz_art, :details, 2, 11
        property :baujahr, :details, 2, 13
        property :erstzul_vn_on, :details, 2, 14
        property :mehrwert_grund, :details, 2, 18
        property :fahrleistung,  :details, 2, 20
        property :garage, :details, 2, 21
        property :nutzungsart, :details, 2, 22
        property :eigentum_fz, :details, 2, 23
        property :wohneigentum, :details, 2, 24
        property :produktname, :details, 2, 25
        property :begin_doppelkarte_on, :details, 2, 28
        property :end_doppelkarte_on, :details, 2, 29
        property :aufbau, :details, 2, 32
        property :gefahrgut, :details, 2, 33
        property :gesamtmasse, :details, 2, 34
        property :staerke_einheit, :details, 2, 35

        property :price, :addl,    1, 8

    end
end
