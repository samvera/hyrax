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

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).reject do |f|
    f == 'bin/rails' || File.dirname(f) =~ %r{\A"?spec\/?}
  end
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.name          = "hyrax"
  spec.require_paths = ["lib"]
  spec.version       = Hyrax::VERSION
  spec.license       = 'Apache-2.0'
  spec.metadata      = { "rubygems_mfa_required" => "true" }

  spec.required_ruby_version = '>= 3.2'

  # NOTE: rails does not follow sem-ver conventions, it's
  # minor version releases can include breaking changes; see
  # http://guides.rubyonrails.org/maintenance_policy.html
  spec.add_dependency 'rails', '~> 7.2', '< 8.0'

  spec.add_dependency 'active-fedora', '~> 15.0'
  spec.add_dependency 'almond-rails', '~> 0.1'
  spec.add_dependency 'awesome_nested_set', '~> 3.1'
  spec.add_dependency 'blacklight', '~> 7.29'
  spec.add_dependency 'blacklight-gallery', '~> 4.7.0'
  spec.add_dependency 'breadcrumbs_on_rails', '~> 3.0'
  spec.add_dependency 'browse-everything', '>= 0.16', '< 2.0'
  spec.add_dependency 'carrierwave', '~> 1.0'
  spec.add_dependency 'clipboard-rails', '~> 1.5'
  spec.add_dependency 'concurrent-ruby', '1.3.4' # Pinned until Rails 7 update
  spec.add_dependency 'connection_pool', '~> 2.4'
  spec.add_dependency 'draper', '~> 4.0'
  spec.add_dependency 'dry-logic', '~> 1.5'
  spec.add_dependency 'dry-container', '~> 0.11'
  spec.add_dependency 'dry-events', '~> 1.0', '>= 1.0.1'
  spec.add_dependency 'dry-monads', '~> 1.6'
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'flipflop', '~> 2.3'
  # Pin more tightly because 0.x gems are potentially unstable
  spec.add_dependency 'flot-rails', '~> 0.0.6'
  spec.add_dependency 'font-awesome-rails', '~> 4.2'
  spec.add_dependency 'google-analytics-data', '~> 0.6'
  spec.add_dependency 'hydra-derivatives', '~> 4.0'
  spec.add_dependency 'hydra-editor', '~> 7.0'
  spec.add_dependency 'hydra-file_characterization', '~> 1.1'
  spec.add_dependency 'hydra-head', '~> 13.0'
  spec.add_dependency 'hydra-works', '>= 0.16'
  spec.add_dependency 'iiif_manifest', '>= 0.3', '< 2.0'
  spec.add_dependency 'json-schema' # for Arkivo
  spec.add_dependency 'legato', '~> 0.3'
  spec.add_dependency 'linkeddata' # Required for getting values from geonames
  spec.add_dependency 'listen', '~> 3.9'
  spec.add_dependency 'mailboxer', '~> 0.12'
  spec.add_dependency 'nest', '~> 3.1'
  spec.add_dependency 'noid-rails', '~> 3.0'
  spec.add_dependency 'oauth'
  spec.add_dependency 'oauth2', '~> 1.2'
  spec.add_dependency 'openseadragon', '~> 0.9'
  spec.add_dependency 'qa', '~> 5.5', '>= 5.5.1' # questioning_authority
  spec.add_dependency 'rails_autolink', '~> 1.1'
  spec.add_dependency 'rdf-rdfxml' # controlled vocabulary importer
  spec.add_dependency 'rdf-vocab', '~> 3.0'
  spec.add_dependency 'redis', '~> 4.0'
  spec.add_dependency 'redis-namespace', '~> 1.5'
  spec.add_dependency 'redlock', '>= 0.1.2', '< 2.0'
  spec.add_dependency 'reform', '~> 2.3'
  spec.add_dependency 'reform-rails', '~> 0.2.0'
  spec.add_dependency 'retriable', '>= 2.9', '< 4.0'
  spec.add_dependency 'signet'
  spec.add_dependency 'tinymce-rails', '~> 5.10'
  spec.add_dependency 'valkyrie', '~> 3.5'
  spec.add_dependency 'view_component', '~> 2.74.1' # Pin until blacklight is updated with workaround for https://github.com/ViewComponent/view_component/issues/1565
  spec.add_dependency 'sprockets', '3.7.2' # 3.7.3 fails feature specs
  spec.add_dependency 'sass-rails', '~> 6.0'
  spec.add_dependency 'select2-rails', '~> 3.5'

  spec.add_development_dependency "capybara", '~> 3.29'
  spec.add_development_dependency 'capybara-screenshot', '~> 1.0'
  spec.add_development_dependency 'database_cleaner', '>= 1.3'
  spec.add_development_dependency "equivalent-xml", '~> 0.5'
  spec.add_development_dependency "factory_bot", '~> 4.4'
  spec.add_development_dependency 'mida', '~> 0.3'
  spec.add_development_dependency 'okcomputer'
  spec.add_development_dependency 'pg', '~> 1.2'
  spec.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
  spec.add_development_dependency 'rspec-rails', '~> 7.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency "selenium-webdriver", '~> 4.4'
  spec.add_development_dependency 'i18n-debug'
  spec.add_development_dependency 'i18n_yaml_sorter'
  spec.add_development_dependency 'rails-controller-testing', '~> 1'
  # the hyrax style guide is based on `bixby`. see `.rubocop.yml`
  spec.add_development_dependency 'bixby', '~> 5.0', '>= 5.0.2' # bixby 5 briefly dropped Ruby 2.5
  spec.add_development_dependency 'shoulda-callback-matchers', '~> 1.1.1'
  spec.add_development_dependency 'shoulda-matchers', '~> 3.1'
  spec.add_development_dependency 'webmock'
end
