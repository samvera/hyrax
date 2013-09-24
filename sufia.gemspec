# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../SUFIA_VERSION",__FILE__)).strip


Gem::Specification.new do |gem|
  gem.authors       = ["Justin Coyne"]
  gem.email         = ["justin.coyne@yourmediashelf.com"]
  gem.description   = %q{Sufia is a Rails engine for creating a self-deposit institutional repository}
  gem.summary       = %q{Sufia was extracted from ScholarSphere developed by Penn State University}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sufia"
  gem.require_paths = ["lib"]
  gem.version       = version
  gem.license       = 'APACHE2'

  gem.add_dependency 'sufia-models', version
  gem.add_dependency 'blacklight', '~> 4.0', '< 4.4' # blacklight 4.4.1/0 doesn't work with kaminari > 0.14.1
  gem.add_dependency 'blacklight_advanced_search', '~> 2.1.0'

  gem.add_dependency 'hydra-batch-edit', '~> 1.0'

  gem.add_dependency 'daemons', '1.1.9'
  gem.add_dependency 'mail_form'
  gem.add_dependency 'rails_autolink', '~> 1.1.0'
  gem.add_dependency 'yaml_db', '0.2.3'
  gem.add_dependency 'rainbow', '1.1.4'
  gem.add_dependency 'font-awesome-sass-rails', '~>3.0'
end
