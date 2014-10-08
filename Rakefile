require "bundler/gem_tasks"
require 'bundler/setup'
APP_ROOT="." # for jettywrapper

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
Dir.glob('tasks/*.rake').each { |r| import r }

require 'jettywrapper'
require 'engine_cart/rake_task'

task ci: ['engine_cart:generate', 'jetty:clean'] do
  ENV['environment'] = "test"
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 90

  Jettywrapper.wrap(jetty_params) do
    # run the tests
    Rake::Task["spec"].invoke
  end
end

task clean: 'engine_cart:clean'
task default: :ci
