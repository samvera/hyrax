# workaround for "invalid byte sequence in US-ASCII (ArgumentError)" breaking the Jenkins build
if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'http://rubygems.org'

# Ruby on Rails components
gem 'rails', '3.2.8'
gem 'mysql2', '0.3.11'

# Hydra community components
gem 'blacklight', '3.6.0'
gem 'blacklight_advanced_search', '1.2.4'
gem 'hydra-head', :git => 'https://github.com/projecthydra/hydra-head.git' 
gem 'active-fedora', '4.5.0'
gem 'rubydora', '0.5.13'
gem 'solrizer-fedora', '2.2.0'
gem 'hydra-ldap', '0.1.0'
gem 'noid', '0.5.5'
gem 'hydra-batch-edit', :git=>'git://github.com/psu-stewardship/hydra-batch-edit.git'

# Other components
gem 'resque', '1.22.0', :require => 'resque/server'
gem 'resque-pool', '0.3.0'
# NOTE: the :require arg is necessary on Linux-based hosts
gem 'rmagick', '2.13.1', :require => 'RMagick'
gem 'devise', '2.1.2'
gem 'paperclip', '3.2.0'
gem 'daemons', '1.1.9'
gem 'execjs', '1.4.0'
gem 'therubyracer', '0.10.2'
gem 'zipruby', '0.3.6'
gem 'mail_form', :git => 'git://github.com/psu-stewardship/mail_form.git', :ref => '50c00f0'
gem 'rails_autolink', '1.0.9'
gem 'acts_as_follower', '0.1.1'
gem 'nest', '1.1.1'
gem 'sitemap', '0.3.2'
gem 'yaml_db', '0.2.3'
gem 'mailboxer', '0.8.0'
gem 'clamav', '0.4.1'
gem 'rainbow', '1.1.4'
gem 'will_paginate', '3.0.3'

group :assets do
  gem 'sass-rails', '3.2.5'
  gem 'coffee-rails', '3.2.2'
  gem 'uglifier', '1.3.0'
  gem 'compass-rails', '1.0.3'
  gem 'compass-susy-plugin', '0.9'
end

group :production, :integration do
  gem 'passenger', '3.0.13'
end

group :development, :test do
  gem 'sqlite3'
  gem 'unicorn-rails'
  gem "debugger"
  gem 'activerecord-import'
  gem "rails_indexes", :git => "git://github.com/warpc/rails_indexes.git", :ref => '4a550270'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'rspec', '2.11.0'
  gem 'rspec-rails', '>= 2.11.0'
  gem 'ruby-prof'
  gem 'mocha', '0.12.4', :require => false
  gem 'cucumber-rails', '~> 1.0', :require => false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
  gem "jettywrapper"
  gem "factory_girl_rails", "~> 4.1.0"
  gem 'launchy'
end # (leave this comment here to catch a stray line inserted by blacklight!)
