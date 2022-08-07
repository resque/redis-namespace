source "https://rubygems.org"

case redis_version = ENV.fetch('REDIS_VERSION', 'latest')
when 'latest'
  gem 'redis', '~> 4.7'
else
  gem 'redis', redis_version
end

platforms :rbx do
  # These are the ruby standard library
  # dependencies of redis-rb, rake, and rspec.
  gem 'rubysl-net-http'
  gem 'rubysl-socket'
  gem 'rubysl-logger'
  gem 'rubysl-cgi'
  gem 'rubysl-uri'
  gem 'rubysl-timeout'
  gem 'rubysl-zlib'
  gem 'rubysl-stringio'
end

gemspec
