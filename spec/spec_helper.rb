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

def capture_stderr(io = nil)
  require 'stringio'
  io ||= StringIO.new
  begin
    original, $stderr = $stderr, io
    yield
  rescue Redis::CommandError 
    # ignore Redis::CommandError for test and
    # return captured messages
    $stderr.string.chomp
  ensure
    $stderr = original
  end
end

def with_env(env = {})
  backup_env = ENV.to_hash.dup
  ENV.update(env)

  yield
ensure
  ENV.replace(backup_env)
end

RSpec::Matchers.define :have_key do |expected|
  match do |redis|
    redis.exists(expected)
  end
end
