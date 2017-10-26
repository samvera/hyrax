# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyrax/version'

Gem::Specification.new do |spec|
  spec.authors       = ["Justin Coyne", 'Michael J. Giarlo', "Carolyn Cole", "Matt Zumwalt", 'Jeremy Friesen', 'Trey Pendragon', 'Esmé Cowles']
  spec.email         = ["jcoyne85@stanford.edu", 'mjgiarlo@stanford.edu', 'cam156@psu.edu', 'matt@databindery.com', "jeremy.n.friesen@gmail.com", 'tpendragon@princeton.edu', 'escowles@ticklefish.org']
  spec.description   = 'Hyrax is a featureful Samvera front-end based on the latest and greatest Samvera software components.'
  spec.summary       = <<-EOF
  Hyrax is a front-end based on the robust Samvera framework, providing a user
  interface for common repository features. Hyrax offers the ability to create
  repository object types on demand, to deposit content via multiple workflows,
  and to describe content with flexible metadata. Numerous optional features may
  be turned on in the administrative dashboard or added through plugins.
EOF

  spec.homepage      = "http://github.com/samvera/hyrax"

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.name          = "hyrax"
  spec.require_paths = ["lib"]
  spec.version       = Hyrax::VERSION
  spec.license       = 'Apache-2.0'

  # Note: rails does not follow sem-ver conventions, it's
  # minor version releases can include breaking changes; see
  # http://guides.rubyonrails.org/maintenance_policy.html
  spec.add_dependency 'rails', '~> 5.0'

  spec.add_dependency 'hydra-head', '>= 10.5.0'
  spec.add_dependency 'hydra-editor', '~> 3.3'
  spec.add_dependency 'hydra-works', '~> 0.16'
  spec.add_dependency 'hydra-derivatives', '~> 3.3'
  spec.add_dependency 'browse-everything', '>= 0.10.5'
  spec.add_dependency 'blacklight', '~> 6.9'
  spec.add_dependency 'blacklight-gallery', '~> 0.7'
  spec.add_dependency 'tinymce-rails', '~> 4.1'
  spec.add_dependency 'font-awesome-rails', '~> 4.2'
  spec.add_dependency 'select2-rails', '~> 3.5'
  spec.add_dependency 'json-schema' # for Arkivo
  spec.add_dependency 'nest', '~> 2.0'
  spec.add_dependency 'mailboxer', '~> 0.12'
  spec.add_dependency 'carrierwave', '~> 1.0'
  spec.add_dependency 'oauth'
  spec.add_dependency 'oauth2', '~> 1.2'
  spec.add_dependency 'signet'
  spec.add_dependency 'legato', '~> 0.3'
  spec.add_dependency 'posix-spawn'
  spec.add_dependency 'jquery-ui-rails', '~> 5.0'
  spec.add_dependency 'redis-namespace', '~> 1.5'
  # Pin more tightly because 0.x gems are potentially unstable
  spec.add_dependency 'flot-rails', '~> 0.0.6'
  spec.add_dependency 'almond-rails', '~> 0.1'
  spec.add_dependency 'qa', '~> 2.0' # questioning_authority
  spec.add_dependency 'flipflop', '~> 2.3'
  spec.add_dependency 'jquery-datatables-rails', '~> 3.4'
  spec.add_dependency 'rdf-rdfxml' # controlled vocabulary importer
  spec.add_dependency 'clipboard-rails', '~> 1.5'
  spec.add_dependency 'rails_autolink', '~> 1.1'
  spec.add_dependency 'active_fedora-noid', '~> 2.0', '>= 2.0.2'
  spec.add_dependency 'awesome_nested_set', '~> 3.1'
  spec.add_dependency 'breadcrumbs_on_rails', '~> 3.0'
  # Pin more tightly because 0.x gems are potentially unstable
  spec.add_dependency 'kaminari_route_prefix', '~> 0.1.1'
  spec.add_dependency 'power_converter', '~> 0.1', '>= 0.1.2'
  spec.add_dependency 'dry-validation', '~> 0.9'
  spec.add_dependency 'dry-equalizer', '~> 0.2'
  spec.add_dependency 'dry-struct', '~> 0.1'
  spec.add_dependency 'redlock', '>= 0.1.2'
  spec.add_dependency 'retriable', '>= 2.9', '< 4.0'
  spec.add_dependency 'active-fedora', '>= 11.3.1'
  spec.add_dependency 'linkeddata' # Required for getting values from geonames
  spec.add_dependency 'hooks', '>= 0.4.1'

  spec.add_development_dependency 'engine_cart', '~> 1.2'
  spec.add_development_dependency 'mida', '~> 0.3'
  spec.add_development_dependency 'database_cleaner', '~> 1.3'
  spec.add_development_dependency 'solr_wrapper', '~> 1.1'
  spec.add_development_dependency 'fcrepo_wrapper', '~> 0.5', '>= 0.5.1'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency "capybara", '~> 2.4'
  spec.add_development_dependency 'capybara-maleficent', '~> 0.2'
  spec.add_development_dependency "chromedriver-helper"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "factory_bot_rails", '~> 4.4'
  spec.add_development_dependency "equivalent-xml", '~> 0.5'
  spec.add_development_dependency "jasmine", '~> 2.3'
  # Pin rubocop and rubocop-rspec tightly. Minor-level version bumps
  # in these gems cause Rubocop violations, and those violations cause
  # continuous integration builds to fail, and those failures prevent
  # us from merging pull requests. As a community, we have decided
  # that it is not reasonable to manage style violations to be dealt
  # with in a pull request *unless* said pull request's intent is to
  # bring the codebase in further alignment with community style
  # conventions. This allows us to take a managed approach to code
  # style -- we choose to update style when we wish, not when a
  # minor-level version bump in a dependency comes out.
  spec.add_development_dependency 'rubocop', '~> 0.49.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.16.0'
  spec.add_development_dependency 'shoulda-matchers', '~> 3.1'
  spec.add_development_dependency 'rails-controller-testing', '~> 1'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'i18n-debug' if ENV['I18N_DEBUG']
  spec.add_development_dependency 'i18n_yaml_sorter' unless ENV['TRAVIS']
end
