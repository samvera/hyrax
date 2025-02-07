# frozen_string_literal: true
#gem 'hyrax', git: 'git://github.com/samvera/hyrax.git', branch: '5.1_rc1-prep'
gem 'hyrax', git: 'https://github.com/samvera/hyrax.git', branch: 'main'
run 'bundle install'
generate 'hyrax:install', '-f'
