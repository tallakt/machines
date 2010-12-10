# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'machines/version'

Gem::Specification.new do |s|
  s.name        = "tallakt-machines"
  s.version     = Machines::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tallak Tveide"]
  s.email       = ["tallak@tveide.net"]
  s.homepage    = "http://github.com/tallakt/machines"
  s.summary     = "Ruby programs in the time domain"

  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency "eventmachine"
  s.add_dependency "rbtree"
  s.add_development_dependency "rspec", "~>1.3"
  s.add_development_dependency "em-spec"

  s.files        = Dir.glob("{bin,lib,spec,tasks}/**/*") + %w(LICENSE README.rdoc CHANGELOG.txt Rakefile)
  s.executables  = []
  s.require_path = 'lib'
end
