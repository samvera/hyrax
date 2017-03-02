gem 'sufia', '7.3.0.rc2'

run 'bundle install'

generate 'sufia:install', '-f'

# Support Rails 4.2 and 5.0
begin
  rails_command 'db:migrate'
  rails_command 'curation_concerns:workflow:load'
rescue NoMethodError
  rake 'db:migrate'
  rake 'curation_concerns:workflow:load'
end
