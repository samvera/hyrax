require 'rspec/core'
require 'rspec/core/rake_task'
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'
require 'active_fedora/rake_support'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

desc 'Run specs and style checker'
task :spec do
  RSpec::Core::RakeTask.new(:spec)
end

desc 'Spin up hydra-jetty and run specs'
task ci: ['rubocop', 'engine_cart:generate'] do
  puts 'running continuous integration'

  # No need to maintain minter state on Travis
  reset_statefile! if ENV['TRAVIS'] == 'true'

  with_test_server do
    Rake::Task['spec'].invoke
  end
end

 def reset_statefile!
   FileUtils.rm_f('/tmp/minter-state')
 end
