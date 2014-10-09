source "https://rubygems.org"

# Specify gem dependencies in hydra-head.gemspec
gemspec

path = File.expand_path('../hydra-core/spec/test_app_templates/Gemfile.extra', __FILE__)
if File.exists?(path)
  eval File.read(path), nil, path
end
