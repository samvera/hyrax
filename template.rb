# Hack for https://github.com/rails/rails/issues/35153
gsub_file 'Gemfile', /^gem ["']sqlite3["']$/, 'gem "sqlite3", "~> 1.3.0"'
gem 'hyrax', '2.9.6'
run 'bundle install'
generate 'hyrax:install', '-f'
rails_command 'db:migrate'
rails_command 'hyrax:default_collection_types:create'
