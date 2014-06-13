lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/namespace/version'

Gem::Specification.new do |s|
  s.name              = "redis-namespace"
  s.version           = Redis::Namespace::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Namespaces Redis commands."
  s.homepage          = "http://github.com/resque/redis-namespace"
  s.email             = ["chris@ozmm.org", "hone02@gmail.com", "steve@steveklabnik.com", "me@yaauie.com"]
  s.authors           = ["Chris Wanstrath", "Terence Lee", "Steve Klabnik", "Ryan Biesemeyer"]
  s.has_rdoc          = false
  s.license           = 'MIT'

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.add_dependency    "redis", "~> 3.1.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.description = <<description
Adds a Redis::Namespace class which can be used to namespace calls
to Redis. This is useful when using a single instance of Redis with
multiple, different applications.
description
end
