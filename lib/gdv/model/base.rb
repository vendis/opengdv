# Base class for all models
class GDV::Model::Base
    def [](sym)
        instance_variable_get(:"@#{sym}")
    end

    def []=(sym)
        instance_variable_set(:"@#{sym}")
    end
end
