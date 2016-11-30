# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'curation_concerns/version'

Gem::Specification.new do |spec|
  spec.name          = "curation_concerns"
  spec.version       = CurationConcerns::VERSION
  spec.authors       = ["Matt Zumwalt", "Justin Coyne", "Jeremy Friesen"]
  spec.email         = ["justin@curationexperts.com"]
  spec.summary       = %q{A Rails Engine that allows an application to CRUD CurationConcern objects (a.k.a. "Works") }
  spec.description   = %q{A Rails Engine that allows an application to CRUD CurationConcern objects (a.k.a. "Works") }
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files | grep -v ^spec/fixtures`.split($\)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'hydra-head', '>= 10.3.0', '< 11'
  spec.add_dependency 'active-fedora', '>= 10.3.0.rc1'
  spec.add_dependency 'blacklight', '~> 6.3'
  spec.add_dependency 'breadcrumbs_on_rails', '>= 3.0.1', '< 4'
  spec.add_dependency 'jquery-ui-rails', '~> 5.0.5'
  spec.add_dependency 'simple_form', '~> 3.1'
  spec.add_dependency 'hydra-editor', '>= 2', '< 4'
  spec.add_dependency 'rails_autolink'
  spec.add_dependency 'sprockets-es6'
  spec.add_dependency 'kaminari_route_prefix', '~> 0.0.1'
  spec.add_dependency 'active_attr'
  spec.add_dependency 'hydra-works', '>= 0.14.0'
  spec.add_dependency 'active_fedora-noid', '~> 2.0.0.beta5'
  spec.add_dependency 'qa', '~> 0.5'
  spec.add_dependency 'redlock', '~> 0.1.2'
  spec.add_dependency 'solrizer', '~> 3.4'
  spec.add_dependency 'rdf', '>= 1.99'
  spec.add_dependency 'rdf-vocab', '>= 0.8'
  spec.add_dependency 'awesome_nested_set', '~> 3.0'
  spec.add_dependency 'browse-everything', '~> 0.10', '>= 0.10.5'
  spec.add_dependency 'clipboard-rails', '~> 1.5'
  spec.add_dependency 'power_converter', '~> 0.1', '>= 0.1.2'
  spec.add_dependency 'dry-validation', '~> 0.9'
  spec.add_dependency 'dry-equalizer', '~> 0.2'
  spec.add_dependency 'dry-struct', '~> 0.1'
  spec.add_dependency 'flot-rails', '~> 0.0.7'
  spec.add_dependency 'highcharts-rails'

  spec.add_development_dependency 'solr_wrapper', '~> 0.16'
  spec.add_development_dependency 'fcrepo_wrapper', '~> 0.1'
  spec.add_development_dependency 'devise', '>= 3.0', '< 5'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "engine_cart", "~> 1.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-rails", '~> 3.5'
  spec.add_development_dependency 'rspec-html-matchers'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'equivalent-xml'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency "capybara", '~> 2.5'
  spec.add_development_dependency "poltergeist", ">= 1.5.0"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "database_cleaner", "< 1.1.0"
  spec.add_development_dependency 'mida', '~> 0.3.4'
  spec.add_development_dependency 'jasmine'
  spec.add_development_dependency 'rubocop', '~> 0.39'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.4.1'
  spec.add_development_dependency 'webmock'
end
