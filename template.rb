gem 'hyrax', '1.0.0.alpha', github: 'projecthydra-labs/hyrax'
gem 'flipflop', git: 'https://github.com/voormedia/flipflop.git', ref: 'e2f3e3d'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
rails_command 'hyrax:workflow:load'
