lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/namespace/version'

Gem::Specification.new do |s|
  s.name              = "redis-namespace"
  s.version           = Redis::Namespace::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Namespaces Redis commands."
  s.homepage          = "https://github.com/resque/redis-namespace"
  s.email             = ["chris@ozmm.org", "hone02@gmail.com", "steve@steveklabnik.com", "me@yaauie.com"]
  s.authors           = ["Chris Wanstrath", "Terence Lee", "Steve Klabnik", "Ryan Biesemeyer"]
  s.license           = 'MIT'

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/resque/redis-namespace/issues",
    "changelog_uri"     => "https://github.com/resque/redis-namespace/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/redis-namespace/#{s.version}",
    "source_code_uri"   => "https://github.com/resque/redis-namespace/tree/v#{s.version}",
  }

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 2.4'

  s.add_dependency    "redis", ">= 3.0.4"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 3.7"
  s.add_development_dependency "rspec-its"

  s.description = <<description
Adds a Redis::Namespace class which can be used to namespace calls
to Redis. This is useful when using a single instance of Redis with
multiple, different applications.
description
end
