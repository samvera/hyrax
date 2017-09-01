gem 'hyrax', '2.0.0.beta1'
run 'bundle install'
generate 'hyrax:install', '-f'
rails_command 'db:migrate'
