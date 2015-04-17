# coding: utf-8
version = File.read(File.expand_path("../../SUFIA_VERSION", __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = "sufia-models"
  spec.version       = version
  spec.authors       = [
    "Jeremy Friesen",
  ]
  spec.email         = [
    "jeremy.n.friesen@gmail.com",
  ]
  spec.description   = %q{Models and services for sufia}
  spec.summary       = %q{Models and services for sufia}

  # This is a temporary homepage until we've had a chance to review the
  # process
  spec.homepage      = "https://github.com/projecthydra/sufia"
  spec.license       = "Apache2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.3"

  spec.add_dependency 'rails', '~> 4.0'
  spec.add_dependency 'activeresource', "~> 4.0" # No longer a dependency of rails 4.0

  spec.add_dependency "hydra-head", "~> 9.0"
  spec.add_dependency "active-fedora", "~> 9.1", ">= 9.1.1"
  spec.add_dependency "hydra-collections", [">= 5.0.2", "< 6.0"]
  spec.add_dependency 'hydra-derivatives', '~> 1.0'
  spec.add_dependency 'active_fedora-noid', '~> 0.1'
  spec.add_dependency 'nest', '~> 1.1'
  spec.add_dependency 'resque', '~> 1.23'
  spec.add_dependency 'resque-pool', '~> 0.3'
  spec.add_dependency 'mailboxer', '~> 0.12'
  spec.add_dependency 'acts_as_follower', '>= 0.1.1', '< 0.3'
  spec.add_dependency 'carrierwave', '~> 0.9'
  spec.add_dependency 'oauth2', '~> 0.9'
  spec.add_dependency 'google-api-client', '~> 0.7'
  spec.add_dependency 'legato', '~> 0.3'
  spec.add_dependency 'activerecord-import', '~> 0.5'
  if RUBY_VERSION < '2.1.0'
    spec.add_dependency 'mini_magick', '< 4'
  else
    spec.add_dependency 'mini_magick'
  end
end
