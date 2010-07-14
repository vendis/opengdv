require 'rake'

GDV_XML = "format/VUVM2009_011109.xml"
RECTYPES = "lib/gdv/format/data/rectypes.txt"

file "format/rectypes.txt" => [ GDV_XML, "format/rectypes.rb" ] do |t|
    ruby "format/rectypes.rb", GDV_XML, RECTYPES
end

desc "Compile GDV XML into parse tables"
task :compile => "format/rectypes.txt"
