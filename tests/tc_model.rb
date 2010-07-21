require 'test_helper'

class TestModel < Test::Unit::TestCase

    def setup
        GDV::Format::init
        @reader = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))
        @trans = GDV::Transmission::parse(@reader)
    end

    def test_transmission
        assert_equal("9999", @trans.vunr)
        assert_equal(14, @trans.contracts.size)
        p = @trans.contracts.first.partner
        assert_equal("2", p.address[1].raw(:anredeschluessel))
        assert_equal("Frau", p.address[1][:anredeschluessel])
        assert_equal("Frau", p.address.anredeschluessel)
        assert_equal("Martina", p.address.name3)
    end
end
