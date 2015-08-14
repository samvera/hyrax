require 'bundler/gem_tasks'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'jettywrapper'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'

Dir.glob('tasks/*.rake').each { |r| import r }

# This makes it possible to run curation_concerns:jetty:config from here.
import 'curation_concerns-models/lib/tasks/curation_concerns-models_tasks.rake'

Jettywrapper.hydra_jetty_version = 'v8.3.1'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

desc 'Run test suite and style checker'
task spec: :rubocop do
  RSpec::Core::RakeTask.new(:spec)
end

task ci: ['engine_cart:generate', 'jetty:clean'] do
  puts 'running continuous integration'
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait] = 90

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  fail "test failures: #{error}" if error
end

task clean: 'engine_cart:clean'
task default: :ci
