gem 'hyrax', '0.0.1.alpha', github: 'projecthydra-labs/hyrax'
gem 'flipflop', github: 'jcoyne/flipflop', branch: 'hydra'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
