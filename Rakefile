task :default => :spec
task :test => :spec

desc "Run specs"
task :spec do
  exec "spec spec/redis_spec.rb"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "redis-namespace"
    gemspec.summary = "Namespaces Redis commands."
    gemspec.description = "Namespaces Redis commands."
    gemspec.email = "chris@ozmm.org"
    gemspec.homepage = "http://github.com/defunkt/redis-namespace"
    gemspec.authors = ["Chris Wanstrath"]
    gemspec.version = '0.2.1'
    gemspec.add_dependency 'redis'
  end
rescue LoadError
  puts "Jeweler not available. Install it with:"
  puts "gem install jeweler"
end
