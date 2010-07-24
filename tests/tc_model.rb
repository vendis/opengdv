require 'test_helper'

class TestModel < Test::Unit::TestCase

    def setup
        GDV::Format::init
        @reader = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))
        @trans = GDV::Model::Transmission::parse(@reader)
    end

    def test_transmission
        assert_equal("9999", @trans.vunr)
        assert_equal(14, @trans.contracts.size)
        c = @trans.contracts.first
        p = c.partner
        assert_equal("2", p.address[1].raw(:anredeschluessel))
        assert_equal("Frau", p.address[1][:anredeschluessel])
        assert_equal("Frau", p.address.anredeschluessel)
        assert_equal("Martina", p.address.name3)
        g = c.general
        assert_not_nil g
        assert_equal("EUR", g[1].raw(21))
        assert_equal("B4LTTT", g[1][25])
    end
end
