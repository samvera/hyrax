# frozen_string_literal: true
# Hack for https://github.com/rails/rails/issues/35153
gem 'hyrax', git: 'git@github.com:samvera/hyrax.git', branch: 'main'
run 'bundle install'
# generate 'hyrax:install', '-f'
