require 'test_helper'

class TestParser < Test::Unit::TestCase

    def setup
        @maps = GDV::Format::Classifier.maps
        @rectypes = GDV::Format::Classifier.rectypes
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

    def test_part_path
        part = GDV::Format::Classifier.find_part(:sid => "0001", :snr => " ")
        assert_not_nil part
        assert_equal "0001", part.rectype.satz
        assert_equal 1, part.nr

        part = GDV::Format::Classifier.find_part(:sid=>"0210",
                                  :sparte=>"160", :snr=>"2")
        assert_not_nil part
        assert_equal "0210", part.rectype.satz
        assert_equal 2, part.nr
        # Sparte 160 benutzt 0210.000
        assert_equal "000", part.rectype.sparte
    end

    def test_yaml_rectype
        rt = @rectypes.first
        yml = rt.to_yaml
        assert_equal "--- !opengdv.vendis.org,2009-11-01/rectype \npath: \n  :sid: \"0001\"\n  :snr: \" \"\n", yml
        assert_equal rt, YAML::load(yml)
    end

    def test_yaml_part
        part = @rectypes.first.parts.last

        yml = YAML::dump(part)
        assert_equal 136, yml.size
        assert_equal part, YAML::load(yml)
    end

    def test_yaml_record
        r = GDV::reader(data_file("muster_bestand.gdv"))
        r.getrec

        rec = r.getrec

        yml = rec.to_yaml
        rec2 = YAML::load(yml)

        assert_equal 985, yml.size
        assert       rec2.known?
        assert_equal rec.lineno, rec2.lineno
        assert_equal rec.rectype, rec2.rectype
        rec.lines.each  do |l|
            l.part.fields.each do |f|
                assert_equal l[f.name], rec2[l.part.nr][f.name],
                             "Wrong #{f.name} in part #{l.part.nr}"
            end
        end
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
        root = GDV::Format::Classifier.instance.recindex
        parts = GDV::Format::Classifier.instance.rectypes.inject([]) { |l, rt| l + rt.parts }
        assert (parts - root.leaves).empty?
    end

    def test_reader
        r = GDV::reader(data_file("muster_bestand.gdv"))

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
            :adressat => "BRBRIENNEE,J\xc3\x9cRGEN",
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

    def test_match
        r = GDV::reader(data_file("muster_bestand.gdv"))
        assert(r.match?(:sid => "0001"))
        assert(! r.match?(:dummy => "X"))
        assert(! r.match?(:sid => "0001", :dummy => "X"))
        assert_raise(GDV::Format::MatchError) { r.match!(:sid => "9999") }
    end

    def test_multiple_addresses
        r = GDV::reader(data_file("multiple_addresses.gdv"))
        assert_not_nil r.match(:sid => "0001")

        rec = r.match(:sid => "0100")
        assert_not_nil rec
        assert_equal   "Kunde", rec.name1

        rec = r.match(:sid => "0100")
        assert_not_nil rec
        assert_equal   "Vermittler", rec.name1
    end

    def test_single_nachsatz
        r = GDV::reader(data_file("multiple_addresses.gdv"))
        while rec = r.getrec
            break if rec.rectype.satz == "9999"
        end
        assert_equal "9999", rec.rectype.satz
        assert_nil r.getrec
    end

    def test_parse_date
        d = Date.civil(2010, 8, 4)
        assert_equal d, GDV::Format.parse_date("04082010")
        d = Date.civil(2010, 1, 1)
        assert_equal d, GDV::Format.parse_date("00002010")
        d = Date.civil(2010, 8, 1)
        assert_equal d, GDV::Format.parse_date("00082010")
    end
end
