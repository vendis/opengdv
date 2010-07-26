# A contract, i.e. everything between the Vorsatz and Nachsatz
require 'gdv/model/partner'

module GDV::Model
    class Contract < Base
        # Erster Partner - der Versicherungsnehmer
        attr_reader :vn

        # Liste weiterer partner
        attr_reader :partner

        attr_reader :general, :signatures, :clauses, :rebates
        attr_reader :sparte

        # Return +true+ if this contract is in sparte +sp+ (one of the
        # constants from Model::Sparte)
        def sparte?(sp)
            sparte.sparte?(sp) if sparte
        end

        property :vsnr,    :general, 1, 5
        property :begin,   :general, 1, 9
        property :end,     :general, 1, 10
        property :renewal, :general, 1, 11

        first Partner

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
