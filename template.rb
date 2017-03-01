gem 'hyrax', '1.0.0.alpha', github: 'projecthydra-labs/hyrax'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
rails_command 'hyrax:workflow:load'
