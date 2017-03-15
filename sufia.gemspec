# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sufia/version'

Gem::Specification.new do |spec|
  spec.authors       = ["Justin Coyne", 'Michael J. Giarlo', "Carolyn Cole", "Matt Zumwalt", 'Jeremy Friesen']
  spec.email         = ["justin@curationexperts.com", 'leftwing@alumni.rutgers.edu', "jeremy.n.friesen@gmail.com"]
  spec.description   = 'Sufia extends the robust Hydra framework to provide a user interface around common repository features and social features. Sufia offers self-deposit, proxy deposit, and configurable mediated deposit workflows. Sufia delivers its rich and growing set of features via a modern, responsive UI'
  spec.summary       = "Sufia was originally extracted from ScholarSphere developed by Penn State University. It's now used and maintained by an active community of adopters."
  spec.homepage      = "http://sufia.io/"

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.name          = "sufia"
  spec.require_paths = ["lib"]
  spec.version       = Sufia::VERSION
  spec.license       = 'Apache2'

  spec.add_dependency 'hydra-works', '~> 0.16'
  spec.add_dependency 'curation_concerns', '~> 1.7.6'
  spec.add_dependency 'hydra-head', '>= 10.4.0'
  spec.add_dependency 'hydra-batch-edit', '~> 2.0'
  spec.add_dependency 'browse-everything', '>= 0.10.3'
  spec.add_dependency 'blacklight', '~> 6.6'
  spec.add_dependency 'blacklight-gallery', '~> 0.7'
  spec.add_dependency 'tinymce-rails', '~> 4.1'
  spec.add_dependency 'tinymce-rails-imageupload', '~> 4.0.16.beta'
  spec.add_dependency 'daemons', '~> 1.1'
  spec.add_dependency 'yaml_db', '~> 0.2'
  spec.add_dependency 'font-awesome-rails', '~> 4.2'
  spec.add_dependency 'select2-rails', '~> 3.5.9'
  spec.add_dependency 'json-schema'
  spec.add_dependency 'nest', '~> 2.0'
  spec.add_dependency 'mailboxer', '~> 0.12'
  spec.add_dependency 'carrierwave', '~> 0.9'
  spec.add_dependency 'oauth'
  spec.add_dependency 'oauth2', '~> 1.2'
  spec.add_dependency 'signet'
  spec.add_dependency 'legato', '~> 0.3'
  spec.add_dependency 'posix-spawn'
  spec.add_dependency 'jquery-ui-rails', '~> 5.0'
  spec.add_dependency 'redis-namespace', '~> 1.5.2'
  spec.add_dependency 'flot-rails', '~> 0.0.6'
  spec.add_dependency 'almond-rails', '~> 0.0.1'
  spec.add_dependency 'qa', '~> 0.8' # questioning_authority
  spec.add_dependency 'flipflop', '~> 2.3'
  spec.add_dependency 'jquery-datatables-rails', '~> 3.4.0'
  spec.add_dependency 'rdf-rdfxml'

  spec.add_development_dependency 'engine_cart', '~> 1.0'
  spec.add_development_dependency 'mida', '~> 0.3'
  spec.add_development_dependency 'database_cleaner', '~> 1.3'
  spec.add_development_dependency 'solr_wrapper', '~> 0.5'
  spec.add_development_dependency 'fcrepo_wrapper', '~> 0.5', '>= 0.5.1'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency "capybara", '~> 2.4'
  spec.add_development_dependency "poltergeist", "~> 1.5"
  spec.add_development_dependency "factory_girl_rails", '~> 4.4'
  spec.add_development_dependency "equivalent-xml", '~> 0.5'
  spec.add_development_dependency "jasmine", '~> 2.3'
  spec.add_development_dependency 'rubocop', '~> 0.42.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.8.0'
  spec.add_development_dependency 'shoulda-matchers', '~> 3.1'
  spec.add_development_dependency 'rails-controller-testing', '~> 0'
end
