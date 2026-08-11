lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/namespace/version'

Gem::Specification.new do |s|
  s.name              = "redis-namespace"
  s.version           = Redis::Namespace::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Namespaces Redis commands."
  s.homepage          = "https://github.com/resque/redis-namespace"
  s.email             = ["chris@ozmm.org", "hone02@gmail.com", "steve@steveklabnik.com", "me@yaauie.com",
                         "mike@mikebian.co"]
  s.authors           = ["Chris Wanstrath", "Terence Lee", "Steve Klabnik", "Ryan Biesemeyer", "Mike Bianco"]
  s.license           = 'MIT'

  s.metadata = {
    "bug_tracker_uri"       => "https://github.com/resque/redis-namespace/issues",
    "changelog_uri"         => "https://github.com/resque/redis-namespace/blob/master/CHANGELOG.md",
    "documentation_uri"     => "https://www.rubydoc.info/gems/redis-namespace/#{s.version}",
    "rubygems_mfa_required" => "true"
  }

  s.files             = %w[README.md Rakefile LICENSE]
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 2.4'

  # NOTE: redis-rb 5.x/6.x reworked several commands (e.g. blpop, multi,
  # pipelined) around keyword arguments and new internals that this gem's
  # argument-namespacing layer does not yet handle correctly (see
  # NECRO_MODERNIZATION_REPORT.md). Pin to the actively-maintained 4.x
  # series until that support lands to avoid silently broken behavior.
  s.add_dependency    "redis", ">= 4.8", "< 5"
  # redis-rb's client internals `require 'cgi'`. Ruby 4.0 unbundled cgi from
  # the default gems (it now only warns, but is slated for full removal);
  # declaring it explicitly keeps that transitive require satisfied.
  s.add_dependency    "cgi"

  s.add_development_dependency "connection_pool"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rspec-its"
  # Ruby 4.0 unbundled logger from the default gems; it's only used by the
  # test suite, but must be declared explicitly to keep `require 'logger'`
  # working in spec_helper.rb.
  s.add_development_dependency "logger"
  s.add_development_dependency "rubocop", "~> 1.89"
  s.add_development_dependency "simplecov", "~> 0.22"

  s.description = <<~DESCRIPTION
    Adds a Redis::Namespace class which can be used to namespace calls
    to Redis. This is useful when using a single instance of Redis with
    multiple, different applications.
  DESCRIPTION
end
