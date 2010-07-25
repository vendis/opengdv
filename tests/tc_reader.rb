# -*- coding: raw-text -*-
require 'test_helper'

class TestParser < Test::Unit::TestCase

    def setup
        GDV::Format::init
        @maps = GDV::Format::maps
        @rectypes = GDV::Format::rectypes
    end

    def test_init_values
        assert @maps.key?(:art_absenders_t)
        typ = @maps[:art_absenders_t]
        assert_equal(4, typ.values.size)
        assert_equal(["1", "2", "3", "9"], typ.values.keys.sort)
        assert_equal("Vermittler", typ.values["2"])
    end

    def test_init_rectypes
        s9999 = @rectypes.select { |rt| rt.satz == "9999" }
        assert_equal(1, s9999.size)
        rectype = s9999.first
        assert_not_nil rectype
        assert_nil rectype.sparte
        assert_equal(1, rectype.parts.size)
        part = rectype.parts[0]
        assert_equal(rectype, part.rectype)
        assert_equal(13, part.fields.size)
        part.fields.each do |f|
            if f.name == :sid
                assert f.const?
                assert_equal(["9999"], f.values)
            else
                assert ! f.const?
            end
        end
        f = part.fields[12]
        assert_equal(13, f.nr)
        assert_equal(part, f.part)
        assert_equal("blank", f.name.to_s)
        assert_equal(100, f.pos)
        assert_equal(157, f.len)
        assert_equal(:space, f.type)
        assert f.values.empty?
    end

    def test_default
        rectype = @rectypes.select { |rt| rt.satz == "9999" }.first
        line = rectype.parts[0].default
        assert_equal(256, line.raw.size)
        assert_equal("9999", line[1])
        assert_equal(0, line[2])
        assert_equal(" " * 10, line.raw(3))
    end

    def test_indexing
        root = GDV::Format::recindex
        parts = GDV::Format::rectypes.inject([]) { |l, rt| l + rt.parts }
        assert (parts - root.leaves).empty?
    end

    def test_reader
        r = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))

        rec = r.getrec
        assert rec.known?
        assert_equal("0001", rec.rectype.satz)
        assert_nil rec.rectype.sparte
        assert_equal("XXX Versicherung AG", rec.absender)
        assert_raises(ArgumentError) { rec.not_a_field }
        assert_equal(2, rec.lines.size)
        assert_equal(1, rec[1].part.nr)

        exp = { :sid => "0001", :vunr => "9999",
            :absender => "XXX Versicherung AG",
            :adressat => "BRBRIENNEE,JÜRGEN",
            :erstellungs_dat_zeitraum_vom_zeitraum_bis => 2207200422072004,
            6 => '9999009999',
            54 => "VU"
        }
        assert_equal("1", rec[1].raw(54))
        exp.keys.each do |k|
            assert_equal(exp[k], rec[1][k])
        end

        while rec = r.getrec
            assert rec.known?
            if rec.rectype.satz == "9999"
                assert_equal(4806.0, rec[1][4])
            elsif rec.rectype.satz == "0200" &&
                    rec[1][5] == "59999999999"
                assert_equal(Date.civil(2004,5,1), rec[1][9])
            end
        end
        assert_equal(165, r.lineno)
    end
end
