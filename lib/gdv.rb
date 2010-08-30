require 'logger'

module GDV
    def self.version
        "0.0.1"
    end

    def self.format_path
        File::join(File::dirname(__FILE__), "gdv", "format", "data")
    end

    # Return a +Logger+
    def self.logger
        unless @logger
            # Create a dummy logger
            self.logger = Logger.new(false)
        end
        @logger
    end

    def self.logger=(logger)
        @logger = logger
        @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    end
end

require 'gdv/format'
require 'gdv/model'
