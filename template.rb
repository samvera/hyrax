gem 'hyrax', '2.0.3'
run 'bundle install'
generate 'hyrax:install', '-f'
rails_command 'db:migrate'
