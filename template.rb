# frozen_string_literal: true

insert_into_file 'config/application.rb', after: /config\.load_defaults [0-9.]+$/ do
  "\n    config.add_autoload_paths_to_load_path = true"
end

# In order to test app generation with local code, un-comment the line below and comment out the other gem definition
# Then run hyrax generation with the flag `-m /path/to/my/local/code/template.rb`
# gem 'hyrax', path: __dir__
gem 'hyrax', '5.2.0'
run 'bundle install'
generate 'hyrax:install', '-f'
