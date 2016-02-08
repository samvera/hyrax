require 'rspec/core'
require 'rspec/core/rake_task'
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'

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
#task ci: [:rubocop, 'engine_cart:generate'] do
task ci: ['engine_cart:generate'] do
  puts 'running continuous integration'
  # No need to maintain minter state on Travis
  reset_statefile! if ENV['TRAVIS'] == 'true'

  # TODO: set port to nil (random port). Requires https://github.com/projecthydra/active_fedora/pull/979
  solr_params = { port: '8985', verbose: true, managed: true }
  fcrepo_params = { port: '8986', verbose: true, managed: true }

  SolrWrapper.wrap(solr_params) do |solr|
    ENV['SOLR_TEST_PORT'] = solr.port
    solr.with_collection(name: 'hydra-test', dir: File.join(File.expand_path('..', File.dirname(__FILE__)), 'solr', 'config')) do
      FcrepoWrapper.wrap(fcrepo_params) do |fcrepo|
        ENV['FCREPO_TEST_PORT'] = fcrepo.port
        Rake::Task['spec'].invoke
      end
    end
  end
end

 def reset_statefile!
   FileUtils.rm_f('/tmp/minter-state')
 end
