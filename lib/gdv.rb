module GDV
    def self.version
        "0.0.1"
    end

    def self.format_path
        File::join(File::dirname(__FILE__), "gdv", "format", "data")
    end

    def self.log(msg)
        true
    end
end

require 'gdv/format.rb'
require 'gdv/transmission.rb'
require 'gdv/contract.rb'
require 'gdv/partner.rb'
