#! /usr/bin/ruby
require 'gdv'

GDV::Parser::init
p GDV::Parser::fields.size
p GDV::Parser::values.size
