require 'test/unit'
require 'gdv'

class TestParser < Test::Unit::TestCase

    def setup
        GDV::Parser::init
    end
        
    def test_init_values
        v = GDV::Parser::values
        assert_equal(158, v.size)
        assert v.key?(:absender_art_t)
        typ = v[:absender_art_t]
        assert typ.is_a?(GDV::Model::Typ)
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
        assert_equal(144, GDV::Parser::rectypes.size)
        rectype = nil
        GDV::Parser::rectypes.each do |rt|
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
        root = nil
        parts = GDV::Parser::rectypes.inject([]) { |l, rt| l + rt.parts }
        begin
            parts.each do |p|
                if root.nil?
                    root = GDV::Model::IndexNode.new(nil, p[:sid], p)
                else
                    root.insert(p)
                end
            end
            #puts "\n\nTree:"
            #puts root.print
            #puts ".\n\n"
        rescue GDV::Model::ModelError => e
            puts root.print
            raise e
        end
        assert (parts - root.leaves).empty?
    end

    def xtest_parse
        #parser = GDV::Parser.new
        #parser.parse_file(data_file("sample.gdv"))
#         GDV::Parser::rectypes.each do |rt|
#             rt.parts.each do |p|
#                 f = [:sid, :snr, :sparte].select { |n| p.field?(n) }
#                 puts "#{p} #{f.join(' ')}"
#             end
#         end
#         return
        print_index(GDV::Parser::build_index, 0, [])
        return
        names = {}
        GDV::Parser::rectypes.each do |rt|
            rt.parts.each do |p|
                puts "RecType #{rt.satz} #{rt.sparte} #{p.nr}"
                p.key_fields.each do |f|
                    puts "  #{f.nr} #{f.name} #{f.pos} #{f.len} '#{f.value}'"
                    names[f.name] = 1
                end
            end
        end
        puts "\n Names: #{names.keys.sort.join("\n")}"
        
    end
    
    def print_index(idx, depth, path)
        pre = "  " * depth
        idx.each do |name, tree| 
            puts "#{pre}#{name}"
            npath = path + [ name ]
            tree.each do |v, p|
                if p.is_a?(GDV::Model::Part)
                    f = npath.select { |n|
                        p.field?(n)
                    }.collect { 
                        |n| "#{n}@#{p[n].pos}+#{p[n].len}" 
                    }.join(" ")
                    puts "#{pre}  #{v}: #{p} #{f}"
                else
                    print_index(p, depth+1, npath)
                end
            end
        end
    end
    
    def data_file(name)
        File::join(File::dirname(__FILE__), "data", name)
    end
end
