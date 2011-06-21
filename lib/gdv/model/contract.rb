# -*- coding: utf-8 -*-
require 'gdv/model/partner'

module GDV::Model
    # A contract, i.e. everything between the Vorsatz and Nachsatz
    class Contract < Base

        grammar do
            # @return [Partner] Erster Partner - der Versicherungsnehmer
            object :vn, Partner
            # @return [Array<Partner>] Liste weiterer partner
            objects :partner, Partner

            # Allgemeiner Teil
            # @return [GDV::Format::Record] 0200 - Allgemeiner Satz
            one    :general, :sid => GENERAL_CONTRACT
            # @return [GDV::Format::Record] 0352 - Signaturen
            star   :signatures, :sid => SIGNATURES
            star   :clauses, :sid => CLAUSES
            star   :rebates, :sid => REBATES

            # Spartenspezifischer Teil
            # @return [Sparte::Kfz] spartenspecifische Sätze
            object :sparte, Sparte::Kfz, Sparte::Kranken, Sparte::Unfall,
                            Sparte::Haftpflicht, Sparte::Rechtsschutz,
                            Sparte::Feuer, Sparte::Glas, Sparte::Hausrat,
                            Sparte::VerbGeb, Sparte::Technische,
                            Sparte::Allgemein

            star   :shares, :sid => SHARE

            # Skip over anything we don't understand
            skip_until :sid => [ADDRESS_TEIL, NACHSATZ]
        end

        first Partner

        # Return +true+ if this contract is in sparte +sp+ (one of the
        # constants from Model::Sparte)
        def sparte?(sp)
            sparte.sparte?(sp) if sparte
        end

        property :vunr,    :general, 1, 2
        property :bkz,     :general, 1, 3
        property :lob,     :general, 1, 4
        property :vsnr,    :general, 1, 5
        property :seq,     :general, 1, 6
        property :vmnr,    :general, 1, 7
        property :inkasso_art, :general, 1, 8
        property :begin_on, :general, 1, 9
        property :end_on,   :general, 1, 10
        property :renewal, :general, 1, 11
        property :zw,      :general, 1, 12

        property :status,  :general, 1, 13
        property :cancelled_reason, :general, 1, 14
        property :cancelled_on, :general, 1, 15

        property :changed_on, :general, 1, 17

        property :beitrag, :general, 1, 22
        property :we,      :general, 1, 21

        property :proposal_written_on, :general, 1, 31

        property :cancel_required, :general, 2, 8
        property :produktform, :general, 2, 10
        property :produktform_ab, :general, 2, 11
        property :beitrag_brutto, :general, 2, 12
        property :vsnr_pretty,    :general, 2, 13
        property :produktname,    :general, 2, 14
        property :proposal_rcvd_on, :general, 2, 16
        property :policy_on,        :general, 2, 17

        def cancelled?
            self.status_raw == "4"
        end

        def bundled?
            self.bkz_raw == "1"
        end

        def effective_on
            changed_on || begin_on
        end
    end
end
