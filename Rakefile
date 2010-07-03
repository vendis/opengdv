require 'rake'

GDV_XML = "format/VUVM2009_011109.xml"

file "format/rectypes.txt" => [ GDV_XML, "format/rectypes.rb" ] do |t|
    ruby "format/rectypes.rb", GDV_XML, "format/rectypes.txt"
end

desc "Compile GDV XML into parse tables"
task :compile => "format/rectypes.txt"
