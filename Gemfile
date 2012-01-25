source 'http://rubygems.org'

gem 'rails', '~> 3.0.10'

gem 'sqlite3'

gem 'active-fedora', :git=>'git://github.com/mediashelf/active_fedora.git', :ref=>'f552f73'
gem 'solrizer-fedora', '>=1.2.2'
gem 'blacklight', '~>3.1.2'
gem 'hydra-head', '~>3.2.0'

gem 'devise'
gem 'delayed_job_active_record'

group :development, :test do
  gem 'ruby-debug'
  gem 'rspec-rails', '>=2.4.0'
  gem 'mocha'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
  gem "jettywrapper"
  gem "factory_girl_rails"
  gem "rspec-expectations" ## Because equivalent-xml depends on RSpec::Matchers being available
  gem 'equivalent-xml'
end # (leave this comment here to catch a stray line inserted by blacklight!)

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
