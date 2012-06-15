# -*- coding: utf-8 -*-
require 'rake'
require 'rdoc/task'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'yard'

GDV_XML = "format/VUVM2009_011109.xml"
RECTYPES = "lib/gdv/format/data/rectypes.txt"

PKG_NAME = 'opengdv'
PKG_VERSION = '0.0.1'
PKG_FILES = FileList[
  "Rakefile",
  "README.rdoc",
  "lib/**/*.rb",
  RECTYPES,
  "tests/**/*.rb",
  "tests/data/*.gdv",
  "bin/*"
]

file RECTYPES => [ GDV_XML, "format/rectypes.rb" ] do |t|
    ruby "format/rectypes.rb", GDV_XML, RECTYPES
end

desc "Compile GDV XML into parse tables"
task :compile => RECTYPES

Rake::RDocTask.new do |t|
    t.main = "README.rdoc"
    t.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

YARD::Rake::YardocTask.new do |t|
  t.options += ['--title', "OpenGDV #{PKG_VERSION} Documentation"]
end

Rake::TestTask.new(:test) do |t|
    t.test_files = FileList['tests/tc_*.rb']
    t.libs = [ 'lib', 'tests/lib' ]
end

task :default => :test

spec = Gem::Specification.new do |s|
    s.author = "David Lutterkort"
    s.email = "lutter@watzmann.net"
    s.platform = Gem::Platform::RUBY
    s.summary = 'Ruby Bibliothek für das Lesen von GDV Dateien'
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.require_path = 'lib'
    s.files = PKG_FILES
    s.description = <<EOF
OpenGDV ist eine Bibliothek zum Lesen von Dateien im GDV Format
(http://gdv-online.de/), einem Standard zum Austausch von Daten über
Versicherungsverträge, Kunden, und andere versicherungsrelevante Details.
EOF
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
end
