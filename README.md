<!-- -*- coding: utf-8 -*- -->

# OpenGDV - eine Bibliothek zm Lesen von GDV Dateien

Diese Bibliothek ermoeglicht es, Dateien im [GDV eNorm
VU-Vermittler](http://www.gdv-online.de/vuvm/) Format zu lesen

## Command Line Usage

Das `bin/` Verzeichnis enthält das Programm `gdview`, mit dem der Inhalt
von GDV Dateien angezeigt werden kann:

    ./bin/gdview tests/data/muster_bestand.gdv

Mittels `gdview --help` kann eine Liste von Optionen angezeigt werden.

Das Programm `gdvmap` kann benutzt werden, um Listen von key/value Paaren,
die im GDV Standard definiert sind, anzuzeigen:

    ./bin/gdmap -d spartenverzeichnis_t --csv

## Aufbau der Bibliothek

Die Bibliothek besteht aus zwei Teilen: dem reader, der für das Lesen und
Aufspalten der Datei in Sätze und Felder verantwortlich ist, und dem model,
das logisch zusammengehörende Sätze in eine Baumstruktur zusammenfaßt.

Der reader bezieht Informationen über die Struktur der Sätze aus der Datei
`lib/gdv/format/data/rectypes.txt`, die aus der XML Beschreibung des GDV
Standards generiert wurde.

Der reader liefert eine GDV Datei Satz für Satz:

    require 'gdv'
    r = GDV::Format::Reader.new("tests/data/muster_bestand.gdv")
    while rec = r.getrec
      puts "#{rec.satz}.#{rec.sparte} vunr: #{rec[1][2]}"
    end

Komfortabler ist der Zugriff über das Modell; hierzu wird erst eine GDV
Datei als `transmission` eingelesen. Die Sätze stehen dann in einer logisch
gegliederten Baumstruktur zur Verfügung:

    require 'gdv'
    tmn = GDV::Model::Transmission.new("tests/data/muster_bestand.gdv")
    puts "#{tmn.contracts_count} Verträge in #{tmn.packages.size} Paketen"
    tmn.packages.each do |pkg|
      puts "VUNR #{pkg.vunr} angelegt vom #{pkg.created_from} bis #{pkg.created_until}"
      pkg.contracts.each do |con|
        puts "VSNR #{con.vsnr} #{con.sparte} #{con.vn.nachname}, #{con.vn.vorname}"
      end
    end

Weitere Entwickerdokumentation befindet sich
[online](http://rdoc.info/github/vendis/opengdv/master/frames)

## License

(The MIT License)

Copyright (c) 2010 [David Lutterkort](http://github.com/lutter)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
