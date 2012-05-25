Gem::Specification.new do |s|
  s.name              = "redis-namespace"
  s.version           = "1.0.3"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Namespaces Redis commands."
  s.homepage          = "http://github.com/defunkt/redis-namespace"
  s.email             = "chris@ozmm.org"
  s.authors           = [ "Chris Wanstrath" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.add_dependency    "redis"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.description = <<description
Adds a Redis::Namespace class which can be used to namespace calls
to Redis. This is useful when using a single instance of Redis with
multiple, different applications.
description
end
