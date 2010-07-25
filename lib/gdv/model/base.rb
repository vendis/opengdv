# Base class for all models
module GDV::Model
    # Constants for the different kinds of 'satz'
    VORSATZ      = "0001"
    NACHSATZ     = "9999"
    ADDRESS_TEIL = "0100"
    SIGNATURES   = "0352"
    CLAUSES      = "0350"
    REBATES      = "0390"
    GENERAL_CONTRACT = "0200"

    module Sparte
        # Spartenkennung
        LEBEN       = "010"
        KRANKEN     = "020"
        UNFALL      = "030"
        HAFTPFLICHT = "040"
        KFZ         = "050" # Kraftfahrt
        RS          = "070" # Rechtsschutz
        FEUER       = "080" # Feuer - Industrie, Gewerbl. Sach
        GLAS        = "010"
        HR          = "130" # Hausrat
        VERB_GEB    = "140" # Verbundene Gebaeude
        TECHN       = "170" # Technsiche
        TRANSPORT   = "190"
        VERKEHR     = "510" # Verkehrsservice
        INV         = "550" # Investmentfonds
        KAPITAL     = "560" # Kapitalanlage
        BAUFIN      = "570" # Baufinanzierung
        BAUSPAR     = "580" # Bausparen
        TIERKRANKEN = "684"
        ALLGEMEIN   = "000"

        # Spartenspezifische Satzarten
        DETAILS     = "0210"
        ADDL        = "0211"
    end

    class Base
        # Lise von Saetzen '0350 - Klausel-Datensatz'
        attr_reader :clauses

        # Liste von Saetzen '0390 - Rabatte und Zuschlaege'
        attr_reader :rebates

        def [](sym)
            instance_variable_get(:"@#{sym}")
        end

        def []=(sym, value)
            instance_variable_set(:"@#{sym}", value)
        end

        def read_property(args, fnr, mode)
            obj = self
            args.each { |arg| obj = obj[arg] }
            if mode == :raw
                obj.raw(fnr)
            else
                obj[fnr]
            end
        end

        class << self
            # Define an instance method +name+ that will retrieve the
            # converted field value described with the path +args+.  Each
            # entry in +args+ except for the last two must be symbols,
            # naming associated objects. The last two entries give the
            # numbers of the part and field to read
            #
            # Also define an instance method +name_raw+ that will retrieve
            # the raw value of the field
            def property(name, *args)
                fnr = args.pop
                define_method(name) do
                    read_property(args, fnr, :convert)
                end
                define_method(:"#{name}_raw") do
                    read_property(args, fnr, :raw)
                end
            end
        end
    end
end