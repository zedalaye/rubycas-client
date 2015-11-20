source 'http://rubygems.org'

group :development do
  gem 'actionpack', '~> 2.3', require: 'action_pack'
  gem 'activerecord', require: 'active_record'
  gem 'bundler', '>= 1.0'
  gem 'database_cleaner', '~> 0.7'
  gem 'guard', '~> 1.0.0'
  gem 'guard-rspec', '~> 0.6'
  gem 'jeweler', '~> 1.8'
  gem 'json', '~> 1.6'
  gem 'rake', '~> 0.9'
  gem 'rspec', '~> 2.8'
  gem 'simplecov', '~> 0.5', require: false

  platforms :ruby do
    gem 'sqlite3', '~> 1.3'
  end

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jruby-openssl'
  end
end

gem 'debugger', '~> 1.6'
gem 'activesupport', '~> 2.3', require: 'active_support'
gem 'nokogiri', '~> 1.6'

