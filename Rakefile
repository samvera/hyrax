#!/usr/bin/env rake

require "bundler/gem_tasks"

Bundler::GemHelper.install_tasks

Dir.glob('tasks/*.rake').each { |r| import r }
import 'sufia-models/lib/tasks/sufia-models_tasks.rake'

desc 'Run CI tests in Travis environment'
task :travis => ['clean', 'ci']

task :default => [:travis]
