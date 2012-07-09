ENV["RAILS_ROOT"] ||= 'spec/internal'
require 'rspec/core/rake_task'

APP_ROOT= File.expand_path(File.join(File.dirname(__FILE__),".."))
require 'jettywrapper'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec => [:generate, :fixtures]) do |t|
  # if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.8/
  #   t.rcov = true
  #   t.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
  # end
  t.rspec_opts = "--colour"
end

task :fixtures do
  within_test_app do
    system "rake hydra:fixtures:refresh RAILS_ENV=test"
  end
end


describe "Create the test rails app"
task :generate do
  unless File.exists?('spec/internal/Rakefile')
    puts "Generating rails app"
    `rails new spec/internal`
    puts "Copying gemfile"
    `cp spec/support/Gemfile spec/internal`
    puts "Copying generator"
    `cp -r spec/support/lib/generators spec/internal/lib`
    within_test_app do
      puts "Bundle install"
      `bundle install`
      puts "running test_app_generator"
      system "rails generate test_app"

      puts "running migrations"
      puts `rake db:migrate db:test:prepare`
    end
  end
  puts "Running specs"
end

describe "Clean out the test rails app"
task :clean do
  puts "Removing sample rails app"
  `rm -rf spec/internal`
end

def within_test_app
  FileUtils.cd('spec/internal')
  yield
  FileUtils.cd('../..')
end
