# coding: utf-8
version = File.read(File.expand_path("../VERSION",__FILE__)).strip

# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "curation_concerns"
  spec.version       = version
  spec.authors       = ["Matt Zumwalt", "Justin Coyne", "Jeremy Friesen"]
  spec.email         = ["justin@curationexperts.com"]
  spec.summary       = %q{A Rails Engine that allows an application to CRUD CurationConcern objects (a.k.a. "Works") }
  spec.description   = %q{A Rails Engine that allows an application to CRUD CurationConcern objects (a.k.a. "Works") }
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'hydra-head' # allow sufia-models to specify the version
  spec.add_dependency "breadcrumbs_on_rails", "~> 2.3.0"
  spec.add_dependency "active_attr"
  spec.add_dependency "simple_form", '~> 3.1.0'
  spec.add_dependency 'curation_concerns-models', version
  spec.add_dependency 'hydra-collections' # allow sufia-models to specify the version
  spec.add_dependency 'hydra-derivatives' # allow sufia-models to specify the version
  spec.add_dependency 'hydra-editor' # allow sufia-models to specify the version

  spec.add_development_dependency "devise", "~> 3.0"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "engine_cart", "~> 0.6"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency 'rspec-html-matchers'
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "poltergeist", ">= 1.5.0"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "database_cleaner", "< 1.1.0"

end
