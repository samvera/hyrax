# frozen_string_literal: true
# Hack for https://github.com/rails/rails/issues/35153
gsub_file 'Gemfile', /^gem ["']sqlite3["']$/, 'gem "sqlite3", "~> 1.3.0"'
gem 'hyrax', '5.0.0.rc2'
run 'bundle install'
generate 'hyrax:install', '-f'
