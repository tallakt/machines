begin
  require 'rubygems'
  gem 'rspec', '~>1.3'
  require 'rspec'
rescue LoadError
  require 'rubygems'
  gem 'rspec', '~>1.3'
  require 'rspec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'machines'



