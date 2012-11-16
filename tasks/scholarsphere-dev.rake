require 'rspec/core'
require 'rspec/core/rake_task'
# namespace :scholarsphere do
#   desc "Execute Continuous Integration build (docs, tests with coverage)"
#   task :ci => :environment do
#     #Rake::Task["hyhead:doc"].invoke
#     Rake::Task["jetty:config"].invoke
#     #Rake::Task["db:drop"].invoke
#     #Rake::Task["db:create"].invoke
#     Rake::Task["db:migrate"].invoke
# 
#     require 'jettywrapper'
#     jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.join(Rails.root, 'jetty'))})
# 
#     error = nil
#     error = Jettywrapper.wrap(jetty_params) do
#         Rake::Task['spec'].invoke
#         Rake::Task['cucumber:ok'].invoke
#     end
#     raise "test failures: #{error}" if error
#   end
# 
ENV["RAILS_ROOT"] ||= 'spec/internal'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => [:generate, :fixtures]) do |t|
  # if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.8/
  #   t.rcov = true
  #   t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
  # end
  t.rspec_opts = "--colour"
end

task :fixtures do
  # within_test_app do
  #   system "rake hydra:fixtures:refresh RAILS_ENV=test"
  # end
end


desc "Create the test rails app"
task :generate do
  unless File.exists?('spec/internal/Rakefile')
    puts "Generating rails app"
    `rails new spec/internal`
    puts "Copying gemfile"
    `cp spec/support/Gemfile spec/internal`
    puts "Copying generator"
    `cp -r spec/support/lib/generators spec/internal/lib`
    Bundler.with_clean_env do
      within_test_app do
        puts "Bundle install"
        `bundle install`
        puts "running test_app_generator"
        system "rails generate test_app"

        puts "running migrations"
        puts `rake db:migrate db:test:prepare`
      end
    end
  end
  puts "Running specs"
end

desc "Clean out the test rails app"
task :clean do
  puts "Removing sample rails app"
  `rm -rf spec/internal`
end

def within_test_app
  FileUtils.cd('spec/internal')
  yield
  FileUtils.cd('../..')
end
  

