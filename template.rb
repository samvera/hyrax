gem 'hyrax', '2.0.2'
run 'bundle install'
generate 'hyrax:install', '-f'
rails_command 'db:migrate'
