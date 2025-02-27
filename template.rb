# frozen_string_literal: true

insert_into_file 'config/application.rb', after: /config\.load_defaults [0-9.]+$/ do
  "\n    config.add_autoload_paths_to_load_path = true"
end

gem 'hyrax', '5.0.4'
run 'bundle install'
generate 'hyrax:install', '-f'
