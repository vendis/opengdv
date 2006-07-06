require 'test/unit'

$:.unshift(File::join(File::dirname(__FILE__), '..', 'lib'))
require 'gdv'

class TestParser < Test::Unit::TestCase

    def setup
        GDV::Format::init
    end
        
    def test_init_values
        v = GDV::Format::values
        assert_equal(158, v.size)
        assert v.key?(:absender_art_t)
        typ = v[:absender_art_t]
        assert typ.is_a?(GDV::Format::Typ)
        assert_equal(4, typ.values.size)
        assert_equal(["1", "2", "3", "9"], typ.values.keys.sort)
        assert_equal("Vermittler", typ.values["2"])
        assert_equal(1, typ.paths.size)
        path = typ.paths[0]
        assert_equal("0001", path.satz)
        assert_equal(1, path.teil)
        assert_equal(54, path.nr)
        assert_nil(path.sparte)
    end

    def test_init_rectypes
        assert_equal(144, GDV::Format::rectypes.size)
        rectype = nil
        GDV::Format::rectypes.each do |rt|
            if rt.satz == "9999"
                assert_nil rectype
                rectype = rt
            end
        end
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
        assert_equal("blank13", f.name.to_s)
        assert_equal(100, f.pos)
        assert_equal(157, f.len)
        assert_equal('space', f.type)
        assert f.values.empty?
    end

    def test_indexing
        root = GDV::Format::recindex
        puts GDV::Format::recindex::print
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
