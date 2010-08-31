require 'test/unit'
require 'gdv'
require 'pp'

class Test::Unit::TestCase

    def data_file(name)
        File::join(File::dirname(__FILE__), "..", "data", name)
    end
end
