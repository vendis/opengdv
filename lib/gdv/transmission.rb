# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
class GDV::Transmission
    attr_reader :vorsatz, :nachsatz, :contracts

    def initialize(reader)
        parse(reader)
    end

    def vunr
        @vorsatz[1][2].strip
    end

    private

    def parse(reader)
        @contracts = []
        rec = reader.getrec
        while rec
            if rec.satz == GDV::Format::VORSATZ
                @vorsatz = rec
                rec = reader.getrec
            elsif rec.satz == GDV::Format::NACHSATZ
                @nachsatz = rec
                rec = reader.getrec
            elsif rec.satz == GDV::Format::ADDRESS_TEIL
                rec = parse_contract(rec, reader)
            else
                rec = reader.getrec
            end
        end
    end

    def parse_contract(addr, reader)
        @contracts << GDV::Contract.new(addr)
        reader.getrec
    end
end
