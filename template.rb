gem 'sufia', '7.2.0'
gem 'flipflop', github: 'jcoyne/flipflop', branch: 'hydra'

run 'bundle install'

generate 'sufia:install', '-f'

# Support Rails 4.2 and 5.0
begin
  rails_command 'db:migrate'
rescue NoMethodError
  rake 'db:migrate'
end
