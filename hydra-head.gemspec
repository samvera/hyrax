# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../HYDRA_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name        = "hydra-head"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Zumwalt, Bess Sadler, Julie Meloni, Naomi Dushay, Jessie Keck, John Scofield, Justin Coyne & many more.  See https://github.com/projecthydra/hydra-head/contributors"]
  s.email       = ["hydra-tech@googlegroups.com"]
  s.homepage    = "http://projecthydra.org"
  s.summary     = %q{Hydra-Head Rails Engine (requires Rails3) }
  s.description = %q{Hydra-Head is a Rails Engine containing the core code for a Hydra application. The full hydra stack includes: Blacklight, Fedora, Solr, active-fedora, solrizer, and om}
  s.files = ['lib/hydra/head.rb']
  s.require_paths = ["lib"]
  s.license = "APACHE2"
    

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency('rails', '~> 4.0')
  s.add_dependency('hydra-access-controls', version)
  s.add_dependency('hydra-core', version)

  s.add_development_dependency "jettywrapper", '~> 1.5'
  s.add_development_dependency "yard" 

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'


end
