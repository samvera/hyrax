gem 'hyrax'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
rails_command 'hyrax:workflow:load'
rails_command 'hyrax:default_collection_type:create'
