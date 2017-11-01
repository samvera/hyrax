gem 'hyrax', '2.0.0.rc2'
run 'bundle install'
generate 'hyrax:install', '-f'
rails_command 'db:migrate'
