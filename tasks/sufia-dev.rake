require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'jettywrapper'

require 'engine_cart/rake_task'

desc 'Spin up hydra-jetty and run specs'
task ci: ['engine_cart:generate', 'jetty:clean', 'sufia:jetty:config'] do
  puts 'running continuous integration'
  jetty_params = Jettywrapper.load_config
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end
