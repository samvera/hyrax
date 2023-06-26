# frozen_string_literal: true
require 'English'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

RSpec::Core::RakeTask.new(:spec)

desc 'Spin up test servers and run specs'
task :spec_with_app_load do
  require 'solr_wrapper'   # necessary for rake_support to work
  require 'fcrepo_wrapper' # necessary for rake_support to work
  require 'active_fedora/rake_support'
  with_test_server do
    Rake::Task['spec'].invoke
  end
end

desc "Sort locales keys in alphabetic order."
task :i18n_sorter do
  require 'i18n_yaml_sorter'
  locales = Dir.glob(File.expand_path('../../config/locales/**/*.yml', __FILE__)) +
            Dir.glob(File.expand_path('../../lib/generators/hyrax/templates/config/locales/**/*.yml', __FILE__)) +
            Dir.glob(File.expand_path('../../lib/generators/hyrax/work/templates//locale.*.yml.erb', __FILE__))
  locales.each do |locale_path|
    sorted_contents = File.open(locale_path) { |f| I18nYamlSorter::Sorter.new(f).sort }
    File.open(locale_path, 'w') { |f| f << sorted_contents }
    abort("Bad I18n conversion!") unless Psych.load_file(locale_path).is_a?(Hash)
  end
end

if Gem.loaded_specs.key? 'engine_cart'
  namespace :engine_cart do
    # This generate task should only add its action to an existing engine_cart:generate task
    raise 'engine_cart:generate task should already be defined' unless Rake::Task.task_defined?('engine_cart:generate')
    task :generate do |_task|
      puts 'Running post-generation operations...'
      Rake::Task['engine_cart:after_generate'].invoke
    end

    desc 'Operations that need to run after the test_app migrations have run'
    task :after_generate do
      puts 'Creating default collection type...'
      EngineCart.within_test_app do
        raise "EngineCart failed on with: #{$CHILD_STATUS}" unless
          system('bundle exec rake hyrax:default_collection_types:create')
      end
    end
  end
end

desc 'Generate the engine_cart and spin up test servers and run specs'
task ci: ['rubocop', 'engine_cart:generate'] do
  puts 'running continuous integration'
  Rake::Task['spec_with_app_load'].invoke
end
