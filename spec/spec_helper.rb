require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
Bundler.require(:default, :test)

require 'rspec'
require 'redis'
require 'logger'

$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'redis/namespace'

RSpec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
