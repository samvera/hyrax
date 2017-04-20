# frozen_string_literal: true

gem 'hyrax', '1.0.0.rc1'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
rails_command 'hyrax:workflow:load'
