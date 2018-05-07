# -*- coding: utf-8 -*-
# Base class for all models
module GDV::Model
    # Constants for the different kinds of 'satz'
    VORSATZ      = "0001"
    NACHSATZ     = "9999"
    ADDRESS_TEIL = "0100"
    SHARE        = "0300"
    SIGNATURES   = "0352"
    CLAUSES      = "0350"
    REBATES      = "0390"
    GENERAL_CONTRACT = "0200"

    module Sparte
        # Spartenkennung
        LEBEN       = "010"
        KRANKEN     = "020"
        UNFALL      = "030"
        HAFTPFLICHT = "040"
        # Kraftfahrt
        KFZ         = "050" # Kraftfahrt
        KFZ_HAFT    = "051" # Kraftfahrzeug-Haftpflichtversicherung
        KFZ_VOLL    = "052" # Fahrzeugvollversicherung
        KFZ_TEIL    = "053" # Fahrzeugteilversicherung
        KFZ_UNFALL  = "054" # Kraftfahrtunfallversicherung
        KFZ_BAUSTEIN = "055" # Kfz-Baustein
        KFZ_GEPAECK = "059" # Kfz-Gepaeck

        RS          = "070" # Rechtsschutz
        FEUER       = "080" # Feuer - Industrie, Gewerbl. Sach
        GLAS        = "010"
        HR          = "130" # Hausrat
        VERB_GEB    = "140" # Verbundene Gebaeude
        TECHN       = "170" # Technsiche
        TRANSPORT   = "190"
        VERKEHR     = "510" # Verkehrsservice
        INV         = "550" # Investmentfonds
        KAPITAL     = "560" # Kapitalanlage
        BAUFIN      = "570" # Baufinanzierung
        BAUSPAR     = "580" # Bausparen
        TIERKRANKEN = "684"
        ALLGEMEIN   = "000"

        # Spartenspezifische Satzarten
        DETAILS     = "0210"
        ADDL        = "0211"
        SPECIFIC    = "0220"
        SPEC_ADDL   = "0221"
    end

    class Base
        # @return [Array<GDV::Format::Record>] 0350 - Klauseln
        attr_reader :clauses

        # @return [Array<GDV::Format::Record>] 0390 - Rabatte und Zuschläge
        attr_reader :rebates

        def [](sym)
            sym = :"@#{sym}"
            if instance_variable_defined?(sym)
                instance_variable_get(sym)
            end
        end

        def []=(sym, value)
            instance_variable_set(:"@#{sym}", value)
        end

        def read_property(args, fnr, mode)
            obj = self
            args.each do |arg|
                obj = obj[arg]
                if obj.nil?
                    raise ArgumentError, "path #{args.inspect} leads to nil at #{arg} for #{self.inspect}" unless mode == :silent
                    return nil
                end
            end
            if mode == :raw
                obj.raw(fnr)
            elsif mode == :orig
                obj.orig_mapped(fnr)
            else
                obj[fnr]
            end
        end

        # Produce a string representation that mirrors the structure of
        # this model object defined by its grammar
        #
        # +opts+ is a hash with the following entries:
        # - +:indent+ - the initial indentation, defaults to ""
        # - +:io+ - the IO object onto which this model will be printed.
        #           If none is given, +format+ returns a string.
        # - +:fields+ - whether to print all fields
        # - +:full+   - print all fields, even empty ones
        # - +:convert+ - convert mapped field values
        def format(opts = {})
          as_string = opts[:io].nil?
          print_header = opts[:header_printed].nil?
          opts[:io] ||= StringIO.new
          io = opts[:io]
          opts[:indent] ||= ""
          indent = opts[:indent]
          if print_header
            io.puts "#{indent}#{self.class.name}"
            opts[:header_printed] = true
          end
          self.class.grammar.rules.each do |r|
            val = self[r.name] if r.name
            case r.kind
            when :one, :maybe
                unless val.nil?
                  io.puts "#{indent}#{r.name}"
                  format_fields(val, opts) if opts[:fields]
                end
            when :star
                io.puts "#{indent}#{r.name} (#{val.size})" unless val.empty?
                val.each { |v| format_fields(v, opts) } if opts[:fields]
            when :object
                unless val.nil?
                  io.puts "#{indent}#{r.name} (#{val.class.name})"
                  val.format(opts.merge(:indent => indent + "  "))
                end
            when :objects
                io.puts "#{indent}#{r.name} (#{val.size})" unless val.empty?
                val.each do |v|
                  io.puts "#{indent}  #{v.class.name}"
                  v.format(opts.merge(:indent => indent + " " * 4))
                end
            end
          end
          as_string ? opts.delete(:io).string : opts[:io]
        end

        def format_fields(rec, opts = {})
          io = opts[:io]
          indent = opts[:indent] +  " " * 4
          rec.lines.each do |l|
            l.part.fields.each do |f|
              v = opts[:convert] ? l[f.nr] : l.raw(f.nr)
              blank = v.strip.empty?
              next if (v.nil? || blank) && !opts[:full]
              lbl = (f.label.nil? ? f.type.to_s : f.label[0,32]) + ":"
              io.printf "#{indent}%2d %-33s %-20s\n", f.nr, lbl, v.strip
            end
            if l == rec.lines.last
              io.puts indent + "=" * (70 - indent.size)
            else
              io.puts indent + "-" * (70 - indent.size)
            end
          end
        end

        private :read_property, :format_fields

        class << self
            # Define an instance method +name+ that will retrieve the
            # converted field value described with the path +args+.  Each
            # entry in +args+ except for the last two must be symbols,
            # naming associated objects. The last two entries give the
            # numbers of the part and field to read
            #
            # Also define an instance method +name_raw+ that will retrieve
            # the raw value of the field, and a method +name_orig+ for the
            # originally mapped value
            def property(name, *args)
                fnr = args.pop
                unless self.instance_methods(false).include?(name)
                    define_method(name) do |*opts|
                        val = nil
                        if opts[0].is_a?(Hash) and opts[0].key?(:default)
                            mode = :silent
                            val = opts[0][:default]
                        else
                            mode = :convert
                        end
                        read_property(args, fnr, mode) || val
                    end
                end
                define_method(:"#{name}_raw") do
                    read_property(args, fnr, :raw)
                end
                define_method(:"#{name}_orig") do
                    read_property(args, fnr, :orig)
                end
            end

            def grammar(&block)
                if block_given?
                    if instance_variable_defined?(:@grammar) && @grammar
                        raise "Klass #{self.name} already has a grammar"
                    end
                    @grammar = Grammar.new(self, &block)
                end
                klass = self
                while klass
                    if g = klass.instance_variable_get(:@grammar)
                        return g
                    end
                    klass = klass.superclass
                end
                nil
            end

            def parse(reader)
                reader.parse(self)
            end

            # Define the conditions to match the first record of this
            # object
            def first(h = nil)
                if h
                    if h.is_a?(Class)
                        @first = h.first
                    else
                        @first = h
                    end
                end
                if instance_variable_defined?(:@first)
                    @first
                else
                    @grammar.first
                end
            end
        end
    end
end
