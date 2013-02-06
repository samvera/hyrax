ENV["RAILS_ROOT"] ||= 'spec/internal'

APP_ROOT= File.expand_path(File.join(File.dirname(__FILE__),".."))
require 'jettywrapper'

desc "Run specs"
task :spec => [:generate, :fixtures] do |t|
  focused_spec = ENV['SPEC'] ? " SPEC=#{File.join(APP_ROOT, ENV['SPEC'])}" : ''
  within_test_app do
    system("rake myspec#{focused_spec}")
    abort "Error running hydra-file-access" unless $?.success?
  end
end

task :fixtures do
  within_test_app do
    system "rake hydra:fixtures:refresh RAILS_ENV=test"
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

desc "Clean out the test rails app"
task :clean do
  puts "Removing sample rails app"
  `rm -rf spec/internal`
end

def within_test_app
  FileUtils.cd('spec/internal')
  Bundler.with_clean_env do
    yield
  end
  FileUtils.cd('../..')
end
