# -*- coding: utf-8 -*-
require 'gdv/model/partner'

module GDV::Model
    # A contract, i.e. everything between the Vorsatz and Nachsatz
    class Contract < Base
        # @return [Partner] Erster Partner - der Versicherungsnehmer
        attr_reader :vn

        # @return [Array<Partner>] Liste weiterer partner
        attr_reader :partner

        # @return [GDV::Format::Record] 0200 - Allgemeiner Satz
        attr_reader :general

        # @return [GDV::Format::Record] 0352 - Signaturen
        attr_reader :signatures

        # @return [Sparte::Kfz] spartenspecifische Sätze
        attr_reader :sparte

        # Return +true+ if this contract is in sparte +sp+ (one of the
        # constants from Model::Sparte)
        def sparte?(sp)
            sparte.sparte?(sp) if sparte
        end

        property :vunr,    :general, 1, 2
        property :bkz,     :general, 1, 3
        property :lob,     :general, 1, 4
        property :vsnr,    :general, 1, 5
        property :agency,  :general, 1, 7
        property :inkasso_art, :general, 1, 8
        property :begin,   :general, 1, 9
        property :end,     :general, 1, 10
        property :renewal, :general, 1, 11
        property :zw,      :general, 1, 12

        property :status,  :general, 1, 13
        property :cancelled_reason, :general, 1, 14
        property :cancelled_on, :general, 1, 15

        property :beitrag, :general, 1, 22
        property :we,      :general, 1, 21


        property :zw,      :general, 1, 12

        first Partner

        def cancelled?
            self.status_raw == "4"
        end

        def bundled?
            self.bkz_raw == "1"
        end

        structure do
            object :vn, Partner
            objects :partner, Partner

            # Allgemeiner Teil
            one    :general, :satz => GENERAL_CONTRACT
            star   :signatures, :satz => SIGNATURES
            star   :clauses, :satz => CLAUSES
            star   :rebates, :satz => REBATES
            # Spartenspezifischer Teil
            object :sparte, Sparte::Kfz
            skip_until :satz => [ADDRESS_TEIL, NACHSATZ]
        end
    end
end
