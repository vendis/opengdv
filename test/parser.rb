require 'test/unit'

$:.unshift(File::join(File::dirname(__FILE__), '..', 'lib'))
require 'gdv'

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
        assert_equal('space', f.type)
        assert f.values.empty?
    end

    def test_indexing
        root = GDV::Format::recindex
        parts = GDV::Format::rectypes.inject([]) { |l, rt| l + rt.parts }
        assert (parts - root.leaves).empty?
    end

    def test_reader
        r = GDV::Format::Reader.new(data_file("muster_bestand.gdv"))
        cnt = 0
        begin
            while r.getrec
                cnt += 1
            end
        rescue GDV::Format::UnknownRecordError => e
            $stderr.puts "#{e.path}:#{e.lineno}:#{e}"
            raise
        end
        assert_equal(165, cnt)
    end

    def data_file(name)
        File::join(File::dirname(__FILE__), "data", name)
    end
end
