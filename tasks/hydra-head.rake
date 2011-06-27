#require 'rake/testtask'
require 'rspec/core'
require 'rspec/core/rake_task'

namespace :hyhead do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do
    Rake::Task["hyhead:doc"].invoke

    Rake::Task["hydra:jetty:config"].invoke
    
    require 'jettywrapper'
    jetty_params = {
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../jetty'),
      :quiet => false,
      :jetty_port => 8983,
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/../jetty/solr'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/../jetty/fedora/default'),
      :startup_wait => 30
      }
    
    # does this make jetty run in TEST environment???
    error = Jettywrapper.wrap(jetty_params) do
      #system("rake hydra:fixtures:refresh environment=test")
      Rake::Task["hyhead:test"].invoke
    end
    raise "test failures: #{error}" if error
  end

  
  desc "Easiest way to run rspec tests. Copies code to host plugins dir, loads fixtures, then runs specs - need to have jetty running."
  task :spec => "rspec:setup_and_run"
  
  namespace :rspec do
      
    desc "Run the hydra-head specs - need to have jetty running, test host set up and fixtures loaded."
    RSpec::Core::RakeTask.new(:run) do |t|
  #    t.spec_opts = ['--options', "/spec/spec.opts"]
      t.pattern = 'spec/**/*_spec.rb'
      t.rcov = true
      t.rcov_opts = lambda do
        IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end
    
    desc "Sets up test host, loads fixtures, then runs specs - need to have jetty running."
    task :setup_and_run => ["hyhead:setup_test_host"] do
      system("rake hydra:fixtures:refresh environment=test")
      Rake::Task["hyhead:rspec:run"].invoke
    end
        
  end

  
  # The following is a task named :doc which generates documentation using yard
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
    doc_destination = File.join(project_root, 'doc')
    if !File.exists?(doc_destination) 
      FileUtils.mkdir_p(doc_destination)
    end

    YARD::Rake::YardocTask.new(:doc) do |yt|
      readme_filename = 'README.textile'
      textile_docs = []
      Dir[File.join(project_root, "*.textile")].each_with_index do |f, index| 
        unless f.include?("/#{readme_filename}") # Skip readme, which is already built by the --readme option
          textile_docs << '-'
          textile_docs << f
        end
      end
      yt.files   = Dir.glob(File.join(project_root, '*.rb')) + 
                   Dir.glob(File.join(project_root, 'app', '**', '*.rb')) + 
                   Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   textile_docs
      yt.options = ['--output-dir', doc_destination, '--readme', readme_filename]
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end
  
#  desc "Easieset way to run cucumber tests. Sets up test host, refreshes fixtures and runs cucumber tests"
#  task :cucumber => "cucumber:setup_and_run"
#  
#  namespace :cucumber do
#      
#    desc "Run cucumber tests for hyhead - need to have jetty running, test host set up and fixtures loaded."
#    task :run => :set_test_host_path do
#      Dir.chdir(TEST_HOST_PATH)
#      puts "Running cucumber features in test host app"
#      puts %x[cucumber --color --tags ~@pending --tags ~@overwritten features]
#      raise "Cucumber tests failed" unless $?.success?
#    end
#    
#    desc "Sets up test host, loads fixtures, then runs cucumber features - need to have jetty running."
#    task :setup_and_run => ["hyhead:setup_test_host"] do
#      system("rake hydra:fixtures:refresh environment=test")
#      Rake::Task["hyhead:cucumber:run"].invoke
#    end    
#  end
#    
#  desc "Copy all of the necessary code into the test host"
#  task :setup_test_host => [:remove_plugin_from_host, :copy_plugin_to_host,:remove_features_from_host, :copy_features_to_host, :remove_fixtures_from_host, :copy_fixtures_to_host] do
#  end
#  
#  desc "Copy the current plugin code into hydra-plugin_test_host/vendor/plugins/hydra-head"
#  task :copy_plugin_to_host => [:set_test_host_path] do
#    excluded = [".", "..", ".git", ".gitignore", ".gitmodules", ".rvmrc", ".yardoc", "coverage", "coverage.data", "doc", "tmp", "hydra-plugin_test_host", "jetty"]
#    plugin_dir = "#{TEST_HOST_PATH}/vendor/plugins/hydra-head"
#    FileUtils.mkdir_p(plugin_dir)
#    
#    puts "Copying plugin files to #{plugin_dir}:"
#
#    Dir.foreach(".") do |fn| 
#      unless excluded.include?(fn)
#        puts " #{fn}"
#        FileUtils.cp_r(fn, "#{plugin_dir}/#{fn}", :remove_destination=>true)
#      end
#    end
#  end

  
  task :set_test_host_path do
    TEST_HOST_PATH = "tmp/test_app"
  end
  
  desc "Creates a new test app and runs the cukes/specs from within it"
  task :setup_test_app => [:set_test_host_path] do
    errors = []
    puts "Cleaning out test app path"
    %x[rm -fr #{TEST_HOST_PATH}]
    errors << 'Error removing test app' unless $?.success?

    FileUtils.mkdir_p(TEST_HOST_PATH)

    puts "Copying over .rvmrc file"
    FileUtils.cp("./test_support/etc/rvmrc",File.join(TEST_HOST_PATH,".rvmrc"))
    FileUtils.cd("tmp")
    system("source ./test_app/.rvmrc")
    
    puts "Installing rails, bundler and devise"
    %x[gem install --no-rdoc --no-ri 'rails']
    %x[gem install --no-rdoc --no-ri 'bundler']
    %x[gem install --no-rdoc --no-ri 'devise']
    
    puts "Generating new rails app"
    %x[rails new test_app]
    errors << 'Error generating new rails test app' unless $?.success?
    FileUtils.cd('test_app')

    puts "Copying Gemfile from test_support/etc"
    FileUtils.cp('../../test_support/etc/Gemfile','./Gemfile')

    puts "Creating local vendor/cache dir and copying gems from hyhead-rails3 gemset"
    FileUtils.cp_r(File.join('..','..','vendor','cache'), './vendor')
    
    puts "Executing bundle install --local"
    %x[bundle install --local]
    errors << 'Error running bundle install in test app' unless $?.success?

    puts "Installing cucumber in test app"
    %x[rails g cucumber:install]
    errors << 'Error installing cucumber in test app' unless $?.success?

    puts "generating default blacklight install"
    %x[rails generate blacklight -d]
    errors << 'Error generating default blacklight install' unless $?.success?

    puts "Running rake db:migrate"
    %x[rake db:migrate]
    
    raise "Errors: #{errors.join("; ")}" unless errors.empty?

  end

  desc "Run tests against test app"
  task :test => [:set_test_host_path] do
    Rake::Task['setup_test_app'].invoke unless File.exist?(TEST_HOST_PATH)
    FileUtils.cd(TEST_HOST_PATH)
    puts "Running rspec tests"
    puts  %x[bundle exec rake hyhead:spec]

    puts "Running cucumber tests"
    puts %x[bundle exec rake hyhead:cucumber]
  end
end
