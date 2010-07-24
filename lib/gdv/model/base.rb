# Base class for all models
class GDV::Model::Base
    def [](sym)
        instance_variable_get(:"@#{sym}")
    end

    def []=(sym, value)
        instance_variable_set(:"@#{sym}", value)
    end
end
