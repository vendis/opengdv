require 'test_helper'

class TestModel < Test::Unit::TestCase

    def setup
        GDV::Format::init
        @reader = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))
        @trans = GDV::Transmission.new(@reader)
    end

    def test_transmission
        assert_equal("9999", @trans.vunr)
        assert_equal(14, @trans.contracts.size)
        c = @trans.contracts.first
        assert_equal("2", c.address[1].raw(:anredeschluessel))
        assert_equal("Frau", c.address[1][:anredeschluessel])
        assert_equal("Frau", c.address.anredeschluessel)
        assert_equal("Martina", c.address.name3)
    end
end
