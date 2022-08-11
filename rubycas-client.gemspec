lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "casclient/version"

Gem::Specification.new do |s|
  s.name = "rubycas-client"
  s.version = CASClient::VERSION
  s.authors = ["Matt Zukowski", "Matt Walker", "Matt Campbell"]

  s.summary = "Client library for the Central Authentication Service (CAS) protocol."
  s.homepage = "https://github.com/rubycas/rubycas-client"
  s.licenses = ["MIT"]

  # Prevent pushing this gem to RubyGems.org.
  s.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rexml'

  s.add_development_dependency 'actionpack', '>= 5.2', '< 7.1'
  s.add_development_dependency 'activerecord', '>= 5.2', '< 7.1'
  s.add_development_dependency 'activerecord-session_store', '>= 0'
  s.add_development_dependency 'activesupport', '>= 5.2', '< 7.1'
  s.add_development_dependency 'appraisal', '~> 2.4'
  s.add_development_dependency 'bundler', '>= 1.0'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'dalli', '~> 2.0'
  s.add_development_dependency 'dice_bag', '>= 0.9', '< 2.0'
  s.add_development_dependency 'database_cleaner', '>= 0'
  s.add_development_dependency 'guard', '>= 0'
  s.add_development_dependency 'guard-rspec', '>= 0'
  s.add_development_dependency 'json', '>= 0'
  s.add_development_dependency 'rake', '>= 0'
  s.add_development_dependency 'redis', '~> 4.5'
  s.add_development_dependency 'redis-actionpack', '~> 5.2'
  s.add_development_dependency 'redis-rack', '~> 2.1'
  s.add_development_dependency 'redis-rails', '~> 5.0'
  s.add_development_dependency 'rspec', '~> 2.0'
  s.add_development_dependency 'simplecov', '>= 0'
  s.add_development_dependency 'sqlite3', '>= 0'
end
