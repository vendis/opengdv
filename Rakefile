require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'

GDV_XML = "format/VUVM2009_011109.xml"
RECTYPES = "lib/gdv/format/data/rectypes.txt"

file "format/rectypes.txt" => [ GDV_XML, "format/rectypes.rb" ] do |t|
    ruby "format/rectypes.rb", GDV_XML, RECTYPES
end

desc "Compile GDV XML into parse tables"
task :compile => "format/rectypes.txt"

Rake::RDocTask.new do |t|
    t.main = "README.rdoc"
    t.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

Rake::TestTask.new(:test) do |t|
    t.test_files = FileList['tests/tc_*.rb']
    t.libs = [ 'lib', 'tests/lib' ]
end
