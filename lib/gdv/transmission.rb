# A class encompassing an entire transmission, i.e. what is usually
# found in one GDV file
class GDV::Transmission
    attr_reader :vorsatz, :nachsatz, :contracts

    def vunr
        @vorsatz[1][2].strip
    end

    def self.parse(reader)
        reader.parse(self) do
            one :vorsatz, :satz => GDV::Format::VORSATZ
            objects :contracts, GDV::Contract,
                      :satz => GDV::Format::ADDRESS_TEIL
            one :nachsatz, :satz => GDV::Format::NACHSATZ
        end
    end
end
