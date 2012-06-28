# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hydra-head/version"

Gem::Specification.new do |s|
  s.name        = "hydra-head"
  s.version     = HydraHead::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Zumwalt, Bess Sadler, Julie Meloni, Naomi Dushay, Jessie Keck, John Scofield, Justin Coyne & many more.  See https://github.com/projecthydra/hydra-head/contributors"]
  s.email       = ["hydra-tech@googlegroups.com"]
  s.homepage    = "http://projecthydra.org"
  s.summary     = %q{Hydra-Head Rails Engine (requires Rails3) }
  s.description = %q{Hydra-Head is a Rails Engine containing the core code for a Hydra application. The full hydra stack includes: Blacklight, Fedora, Solr, active-fedora, solrizer, and om}

  s.add_dependency "rails", '~>3.2.3' 
  s.add_dependency "blacklight", '~>3.4'  
  s.add_dependency "devise"
  s.add_dependency "active-fedora", '~>4.1'
  s.add_dependency 'RedCloth', '=4.2.9'
  s.add_dependency 'block_helpers'
  s.add_dependency 'sanitize'
  s.add_dependency 'hydra-mods', ">= 0.0.5"
  s.add_dependency 'deprecation', ">= 0.0.5"
  s.add_dependency 'jquery-rails'
  s.add_dependency 'hydra-access-controls', ">= 0.0.2"
  
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'jettywrapper', ">=1.3.0"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'cucumber-rails', '>=1.2.0'
  s.add_development_dependency 'factory_girl', "~> 2.6.0"
  s.add_development_dependency 'solrizer-fedora', '>=2.1.0'


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
