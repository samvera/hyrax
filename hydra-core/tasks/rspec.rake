ENV["RAILS_ROOT"] ||= 'spec/internal'

GEM_ROOT= File.expand_path(File.join(File.dirname(__FILE__),".."))

desc "Run specs"
task spec: :generate do |t|
  focused_spec = ENV['SPEC'] ? " SPEC=#{File.join(GEM_ROOT, ENV['SPEC'])}" : ''
  within_test_app do
    system "rake myspec#{focused_spec}"
    abort "Error running hydra-core" unless $?.success?
  end
end


desc "Create the test rails app"
task :generate do
  unless File.exists?('spec/internal/Rakefile')
    puts "Generating rails app"
    `rails new spec/internal`
    puts "Updating gemfile"
    `echo " gem 'hydra-access-controls', :path=>'../../../hydra-access-controls'" >> spec/internal/Gemfile`
    `echo " gem 'hydra-core', :path=>'../../', :require=>'hydra-core'" >> spec/internal/Gemfile`
    `echo " eval File.read('../test_app_templates/Gemfile.extra'), nil, '../test_app_templates/Gemfile.extra'" >> spec/internal/Gemfile`
    `echo " gem 'factory_girl_rails'" >> spec/internal/Gemfile`
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
