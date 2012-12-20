# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sufia/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Coyne"]
  gem.email         = ["justin.coyne@yourmediashelf.com"]
  gem.description   = %q{Engine for PSU scholarsphere}
  gem.summary       = %q{A generic hyda-head repository}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sufia"
  gem.require_paths = ["lib"]
  gem.version       = Sufia::VERSION

  gem.add_dependency 'rails', '~> 3.2.8'
  gem.add_dependency 'blacklight', '~> 4.0.0'
  gem.add_dependency 'blacklight_advanced_search'
  gem.add_dependency "hydra-head", "~> 5.0.0"

  #TODO remove
  gem.add_dependency 'noid', '0.5.5'
  gem.add_dependency 'hydra-batch-edit', '~> 0.0.7'

# Other components
  gem.add_dependency 'resque', '~> 1.23.0'#, :require => 'resque/server'
  gem.add_dependency 'resque-pool', '0.3.0'
# NOTE: the :require arg is necessary on Linux-based hosts
  gem.add_dependency 'rmagick', '2.13.1'#, :require => 'RMagick'
  gem.add_dependency 'devise', '2.1.2'
  gem.add_dependency 'paperclip', '3.3.0'
  gem.add_dependency 'daemons', '1.1.9'
  gem.add_dependency 'execjs', '1.4.0'
  gem.add_dependency 'therubyracer', '0.10.2'
  gem.add_dependency 'zipruby', '0.3.6'
  gem.add_dependency 'mail_form'
  gem.add_dependency 'rails_autolink', '1.0.9'
  gem.add_dependency 'acts_as_follower', '0.1.1'
  gem.add_dependency 'nest', '1.1.1'
  gem.add_dependency 'sitemap', '0.3.2'
  gem.add_dependency 'yaml_db', '0.2.3'
  gem.add_dependency 'mailboxer', '0.8.0'
  gem.add_dependency 'rainbow', '1.1.4'
  gem.add_dependency 'will_paginate', '3.0.3'
  gem.add_dependency 'activerecord-import'
end
