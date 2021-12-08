# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hyrax/version'

Gem::Specification.new do |spec|
  spec.authors       = ["Justin Coyne", 'Michael J. Giarlo', "Carolyn Cole", "Matt Zumwalt", 'Jeremy Friesen', 'Trey Pendragon', 'Esmé Cowles']
  spec.email         = ["jcoyne85@stanford.edu", 'mjgiarlo@stanford.edu', 'cam156@psu.edu', 'matt@databindery.com', "jeremy.n.friesen@gmail.com", 'tpendragon@princeton.edu', 'escowles@ticklefish.org']
  spec.description   = 'Hyrax is a featureful Samvera front-end based on the latest and greatest Samvera software components.'
  spec.summary       = <<-SUMMARY
  Hyrax is a front-end based on the robust Samvera framework, providing a user
  interface for common repository features. Hyrax offers the ability to create
  repository object types on demand, to deposit content via multiple workflows,
  and to describe content with flexible metadata. Numerous optional features may
  be turned on in the administrative dashboard or added through plugins.
SUMMARY

  spec.homepage      = "http://github.com/samvera/hyrax"

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).select { |f| File.dirname(f) !~ %r{\A"?spec\/?} }
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.name          = "hyrax"
  spec.require_paths = ["lib"]
  spec.version       = Hyrax::VERSION
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = '>= 2.5'

  # Note: rails does not follow sem-ver conventions, it's
  # minor version releases can include breaking changes; see
  # http://guides.rubyonrails.org/maintenance_policy.html
  spec.add_dependency 'rails', '~> 5.0'

  spec.add_dependency 'active-fedora', '~> 13.1', '>= 13.1.2'
  spec.add_dependency 'almond-rails', '~> 0.1'
  spec.add_dependency 'awesome_nested_set', '~> 3.1'
  spec.add_dependency 'blacklight', '~> 7.0'
  spec.add_dependency 'blacklight-gallery', '~> 1.0'
  spec.add_dependency 'breadcrumbs_on_rails', '~> 3.0'
  spec.add_dependency 'browse-everything', '>= 0.16', '< 2.0'
  spec.add_dependency 'carrierwave', '~> 1.0'
  spec.add_dependency 'clipboard-rails', '~> 1.5'
  spec.add_dependency 'draper', '~> 4.0'
  spec.add_dependency 'dry-events', '~> 0.2.0'
  spec.add_dependency 'dry-equalizer', '~> 0.2'
  spec.add_dependency 'dry-struct', '~> 1.0'
  spec.add_dependency 'dry-transaction', '~> 0.11'
  spec.add_dependency 'dry-validation', '~> 1.3'
  spec.add_dependency 'flipflop', '~> 2.3'
  # Pin more tightly because 0.x gems are potentially unstable
  spec.add_dependency 'flot-rails', '~> 0.0.6'
  spec.add_dependency 'font-awesome-rails', '~> 4.2'
  spec.add_dependency 'hydra-derivatives', '~> 3.3'
  spec.add_dependency 'hydra-editor', '~> 5.0', ">= 5.0.4"
  spec.add_dependency 'hydra-file_characterization', '~> 1.1.2'
  spec.add_dependency 'hydra-head', '~> 12.0'
  spec.add_dependency 'hydra-works', '>= 0.16'
  spec.add_dependency 'iiif_manifest', '>= 0.3', '< 2.0'
  spec.add_dependency 'jquery-datatables-rails', '~> 3.4'
  spec.add_dependency 'jquery-ui-rails', '~> 6.0'
  spec.add_dependency 'json-schema' # for Arkivo
  # Pin more tightly because 0.x gems are potentially unstable
  spec.add_dependency 'kaminari_route_prefix', '~> 0.1.1'
  spec.add_dependency 'legato', '~> 0.3'
  spec.add_dependency 'linkeddata' # Required for getting values from geonames
  spec.add_dependency 'mailboxer', '~> 0.12'
  spec.add_dependency 'nest', '~> 3.1'
  spec.add_dependency 'noid-rails', '~> 3.0.0'
  spec.add_dependency 'oauth'
  spec.add_dependency 'oauth2', '~> 1.2'
  spec.add_dependency 'posix-spawn'
  spec.add_dependency 'power_converter', '~> 0.1', '>= 0.1.2'
  spec.add_dependency 'qa', '~> 5.5', '>= 5.5.1' # questioning_authority
  spec.add_dependency 'rails_autolink', '~> 1.1'
  spec.add_dependency 'rdf-rdfxml' # controlled vocabulary importer
  spec.add_dependency 'rdf-vocab', '~> 3.0'
  spec.add_dependency 'redis-namespace', '~> 1.5'
  spec.add_dependency 'redlock', '>= 0.1.2'
  spec.add_dependency 'reform', '~> 2.3'
  spec.add_dependency 'reform-rails', '~> 0.2.0'
  spec.add_dependency 'retriable', '>= 2.9', '< 4.0'
  spec.add_dependency 'samvera-nesting_indexer', '~> 2.0'
  spec.add_dependency 'select2-rails', '~> 3.5'
  spec.add_dependency 'signet'
  spec.add_dependency 'tinymce-rails'
  spec.add_dependency 'valkyrie', '~> 2', '>= 2.1.1'

  spec.add_development_dependency "capybara", '~> 3.29'
  spec.add_development_dependency 'capybara-screenshot', '~> 1.0'
  spec.add_development_dependency 'database_cleaner', '~> 1.3'
  spec.add_development_dependency 'engine_cart', '~> 2.2'
  spec.add_development_dependency "equivalent-xml", '~> 0.5'
  spec.add_development_dependency "factory_bot", '~> 4.4'
  spec.add_development_dependency 'fcrepo_wrapper', '~> 0.5', '>= 0.5.1'
  spec.add_development_dependency "jasmine", '~> 2.3', '< 2.99'
  spec.add_development_dependency "jasmine-core", '~> 2.3', '< 2.99'
  spec.add_development_dependency 'mida', '~> 0.3'
  spec.add_development_dependency 'okcomputer'
  spec.add_development_dependency 'pg', '~> 1.2'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
  spec.add_development_dependency 'rspec-rails', '~> 3.1'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency 'i18n-debug'
  spec.add_development_dependency 'i18n_yaml_sorter'
  spec.add_development_dependency 'rails-controller-testing', '~> 1'
  # the hyrax style guide is based on `bixby`. see `.rubocop.yml`
  spec.add_development_dependency 'bixby', '~> 3.0', ">= 3.0.2"
  spec.add_development_dependency 'shoulda-callback-matchers', '~> 1.1.1'
  spec.add_development_dependency 'shoulda-matchers', '~> 3.1'
  spec.add_development_dependency 'webdrivers', '~> 4.4'
  spec.add_development_dependency 'webmock'

  ########################################################
  # Temporarily pinned dependencies. INCLUDE EXPLANATIONS.
  #
  # Pin sass-rails to 5.x because rails 5.x apps have this same dependency in their generated Gemfiles
  # See https://github.com/samvera/hyrax/issues/3919
  spec.add_dependency 'sass-rails', '~> 5.0'
end
