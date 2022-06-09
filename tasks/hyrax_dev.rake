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

# rubocop:disable Metrics/BlockLength

Rake::Task["engine_cart:create_test_rails_app"].clear

namespace :engine_cart do
  task create_test_rails_app: [:setup] do
    require 'tmpdir'
    require 'fileutils'
    Dir.mktmpdir do |dir|
      # Fork into a new process to avoid polluting the current one with the partial Rails environment ...
      pid = fork do
        Dir.chdir dir do
          require 'rails/generators'
          require 'rails/generators/rails/app/app_generator'

          # Clear out our current bundle so that the rails generator can run with it's own bundle
          backup_gemfile = ENV['BUNDLE_GEMFILE']
          ENV.delete('BUNDLE_GEMFILE')

          # Using the Rails generator directly, instead of shelling out, to
          # ensure we use the right version of Rails.
          Rails::Generators::AppGenerator.start([
            'internal',
            '--skip-git',
            '--skip-keeps',
            '--skip_spring',
            '--skip-bootsnap',
            '--skip-listen',
            '--skip-test',
            '--skip-javascript',
            *EngineCart.rails_options,
            ("-m #{EngineCart.template}" if EngineCart.template)
          ].compact)

          # Restore our gemfile
          ENV['BUNDLE_GEMFILE'] = backup_gemfile
        end
        exit 0
      end

      # ... and then wait for it to catch up.
      _, status = Process.waitpid2 pid
      exit status.exitstatus unless status.success?

      Rake::Task['engine_cart:clean'].invoke if File.exist? EngineCart.destination
      FileUtils.move "#{dir}/internal", EngineCart.destination.to_s
    end
  end
end

Rake::Task["engine_cart:generate"].clear

namespace :engine_cart do
  desc "Create the test rails app"
  task generate: [:setup] do
    if EngineCart.fingerprint_expired?

      # Create a new test rails app
      Rake::Task['engine_cart:create_test_rails_app'].invoke
      Rake::Task['engine_cart:inject_gemfile_extras'].invoke

      # Copy our test app generators into the app and prepare it
      Bundler.clean_system "cp -r #{EngineCart.templates_path}/lib/generators #{EngineCart.destination}/lib" if File.exist? "#{EngineCart.templates_path}/lib/generators"

      within_test_app do
        unless (system("bundle install --quiet") || system("bundle update --quiet")) &&
               system("(bundle exec rails g | grep test_app) && bundle exec rails generate test_app") &&
               system("bundle exec rake db:migrate") &&
               system("bundle exec rake db:test:prepare")
          raise "EngineCart failed on with: #{$CHILD_STATUS}"
        end
      end

      Bundler.clean_system "bundle install --quiet"

      EngineCart.write_fingerprint

      puts "Done generating test app"
    end
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

# rubocop:enable Metrics/BlockLength

desc 'Generate the engine_cart and spin up test servers and run specs'
task ci: ['rubocop', 'engine_cart:generate'] do
  puts 'running continuous integration'
  Rake::Task['spec_with_app_load'].invoke
end
