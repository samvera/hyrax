#!/usr/bin/env rake

require "bundler/gem_tasks"
Dir.glob('tasks/*.rake').each { |r| import r }

desc 'Run CI tests in Travis environment'
task :travis => ['clean', 'ci']

task :default => [:travis]
