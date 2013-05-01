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

def capture_stderr
  require 'stringio'
  begin
    original, $stderr = $stderr, StringIO.new
    yield
  rescue Redis::CommandError 
    # ignore Redis::CommandError for test and
    # return captured messages
    $stderr.string.chomp
  ensure
    $stderr = original
  end
end

RSpec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
