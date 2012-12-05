require 'rspec/core'
require 'rspec/core/rake_task'
APP_ROOT="." # for jettywrapper
require 'jettywrapper'
ENV["RAILS_ROOT"] ||= 'spec/internal'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => [:generate]) do |t|
  # if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.8/
  #   t.rcov = true
  #   t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
  # end
  t.rspec_opts = "--colour"
end

desc "Load scholarsphere fixtures"
task :fixtures => :generate do# => ['sufia:fixtures:refresh'] do
  #NOTE do we need fixtures:create, fixtures:generate
  within_test_app do
    puts "Loading fixtures "
    ENV["RAILS_ENV"] = 'test'
    puts `rake sufia:fixtures:refresh`
  end
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
  
namespace :meme do
  desc "configure jetty to generate checksums"
  task :config do
  end
end
