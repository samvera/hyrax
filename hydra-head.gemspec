# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hydra-head/version"

Gem::Specification.new do |s|
  s.name        = "hydra-head"
  s.version     = HydraHead::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Zumwalt, Bess Sadler, Naomi Dushay, Jessie Keck, John Scofield & many more.  See https://github.com/projecthydra/hydra-head/contributors"]
  s.email       = ["hydra-tech@googlegroups.com"]
  s.homepage    = "http://projecthydra.org"
  s.summary     = %q{Hydra Repository Rails Engine (requires Rails3) }
  s.description = %q{Hydra-Head is a Rails Engines plugin containing the core code for a Hydra application. The full hydra stack includes: Blacklight, Fedora, Solr, active-fedora, solrizer, and om}

  s.add_dependency "rails", '>= 3.0'
  # s.add_dependency "blacklight", '~> 3.0.0pre6'
  s.add_dependency "blacklight", '3.0.0pre8'  
  s.add_dependency "active-fedora", '>= 2.3.0'
  s.add_dependency 'builder'
  s.add_dependency 'columnize'
  s.add_dependency 'crack'
  s.add_dependency 'curb'
  s.add_dependency 'database_cleaner'
  s.add_dependency 'diff-lcs'
  s.add_dependency 'facets', '2.8.4'
  s.add_dependency 'haml'
  s.add_dependency 'httparty'
  s.add_dependency 'jettywrapper'
  s.add_dependency 'json_pure', '>1.4.3'
  s.add_dependency 'launchy'
  s.add_dependency 'linecache'
  s.add_dependency 'mime-types'
  s.add_dependency 'multipart-post'
  s.add_dependency 'nokogiri' # Default to using the version required by Blacklight
  s.add_dependency 'om', '>=1.2.3'
  s.add_dependency 'rack'
  s.add_dependency 'rack-test'
  s.add_dependency 'rake'
  s.add_dependency 'rcov'
  s.add_dependency 'RedCloth', '=4.2.3'
  s.add_dependency 'solr-ruby' 
  s.add_dependency 'solrizer', '>=1.1.0'
  s.add_dependency 'solrizer-fedora', '>=1.1.0'
  s.add_dependency 'sqlite3-ruby', '1.2.5'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'trollop'
  s.add_dependency 'will_paginate'
  s.add_dependency 'xml-simple'
  s.add_dependency 'yard'
  s.add_dependency 'block_helpers'
  s.add_dependency 'sanitize'

  s.add_development_dependency 'ruby-debug'
  s.add_development_dependency 'ruby-debug-base'
  s.add_development_dependency 'rspec', '>= 2.0.0'  
  s.add_development_dependency 'rspec-rails', '>= 2.0.0' # rspec-rails 2.0.0 requires Rails 3.
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'cucumber', '>=0.8.5'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'gherkin'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'markup_validity'
  s.add_development_dependency "rake"


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
