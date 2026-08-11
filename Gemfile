source "https://rubygems.org"

case redis_version = ENV.fetch('REDIS_VERSION', 'latest')
when 'latest'
  gem 'redis', '~> 4'
else
  gem 'redis', "~> #{redis_version}"
end

platforms :rbx do
  # These are the ruby standard library
  # dependencies of redis-rb, rake, and rspec.
  gem 'rubysl-cgi'
  gem 'rubysl-logger'
  gem 'rubysl-net-http'
  gem 'rubysl-socket'
  gem 'rubysl-stringio'
  gem 'rubysl-timeout'
  gem 'rubysl-uri'
  gem 'rubysl-zlib'
end

gemspec
