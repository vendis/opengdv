require 'test_helper'

class TestModel < Test::Unit::TestCase

    def setup
        GDV::Format::init
        @reader = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))
        @trans = GDV::Model::Package::parse(@reader)
    end

    def test_transmission
        assert_equal("9999", @trans.vunr)
        assert_equal(14, @trans.contracts.size)
        c = @trans.contracts.first
        p = c.vn
        assert_equal("2", p.anrede_raw)
        assert_equal("Frau", p.anrede)
        assert_equal("", p.geburtsort)

        assert_equal("Frau", p.address.anredeschluessel)
        assert_equal("Martina", p.address.name3)
        g = c.general
        assert_not_nil g
        assert_equal("EUR", g[1].raw(21))
        assert_equal("B4LTTT", g[1][25])
    end

    def test_kfz
        contracts = contracts_for(GDV::Model::Sparte::KFZ)
        assert_equal(4, contracts.size)

        c = contracts.first
        assert_not_nil c

        assert_equal("Gillensvier", c.vn.nachname)
        assert_equal("Herbert", c.vn.vorname)
        assert_equal("W45KKK", c.vn.kdnr_vu)

        assert_equal("59999999990", c.vsnr)
        assert_equal(Date.civil(2004, 7, 1), c.begin)
        assert_equal(Date.civil(2005,1,1), c.end)
        assert_equal(Date.civil(2005,1,1), c.renewal)

        kfz = c.sparte
        assert_equal("VW", kfz.make)
        assert_equal('1J (GOLF IV 1.9 TDI SYNCR', kfz.model)
        assert_equal(0, kfz.price)

        assert_not_nil kfz.haft
        assert_equal("R8", kfz.haft.regionalklasse)
        assert_equal("1/2", kfz.haft.sfs)
        assert_equal(866.87, kfz.haft.beitrag)

        assert_not_nil kfz.teil
        assert_equal("22", kfz.teil.typkl)
        assert_equal(173.58, kfz.teil.beitrag)

        assert_not_nil kfz.unfall
        assert_equal("1", kfz.unfall.deckung1_raw)
        assert_equal(30000.0, kfz.unfall.invaliditaet)
    end

    def contracts_for(sp)
        @trans.contracts.select { |c| c.sparte?(sp) }
    end
end
