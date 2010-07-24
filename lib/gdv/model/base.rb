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
    SPECIFIC_CONTRACT = "0210"

    class Base

        def [](sym)
            instance_variable_get(:"@#{sym}")
        end

        def []=(sym, value)
            instance_variable_set(:"@#{sym}", value)
        end
    end
end
