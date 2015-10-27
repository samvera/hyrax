#!/usr/bin/env rake

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

Dir.glob('tasks/*.rake').each { |r| import r }
import 'sufia-models/lib/tasks/sufia-models_tasks.rake'

# Pull in jetty-related tasks from CurationConcerns rather than duplicate them
require 'curation_concerns'
spec = Gem::Specification.find_by_name 'curation_concerns'
load "#{spec.gem_dir}/tasks/jetty.rake"

spec = Gem::Specification.find_by_name 'curation_concerns-models'
load "#{spec.gem_dir}/lib/tasks/curation_concerns-models_tasks.rake"

task default: :ci
