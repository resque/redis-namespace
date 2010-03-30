task :default => :spec
task :test    => :spec

desc "Build a gem"
task :gem => [ :gemspec, :build ]

desc "Run specs"
task :spec do
  exec "spec spec/redis_spec.rb"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "redis-namespace"
    gemspec.summary = "Namespaces Redis commands."
    gemspec.email = "chris@ozmm.org"
    gemspec.homepage = "http://github.com/defunkt/redis-namespace"
    gemspec.authors = ["Chris Wanstrath"]
    gemspec.version = '0.4.0'
    gemspec.add_dependency 'redis'
    gemspec.description = <<description
Adds a Redis::Namespace class which can be used to namespace calls
to Redis. This is useful when using a single instance of Redis with
multiple, different applications.
description
  end
rescue LoadError
  warn "Jeweler not available. Install it with:"
  warn "gem install jeweler"
end
