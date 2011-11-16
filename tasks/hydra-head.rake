require 'rspec/core'
require 'rspec/core/rake_task'
require 'thor/core_ext/file_binary_read'

namespace :hyhead do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do
    Rake::Task["hyhead:doc"].invoke
    Rake::Task["hydra:jetty:config"].invoke
    
    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/../jetty')})
    
    error = nil
    error = Jettywrapper.wrap(jetty_params) do
        Rake::Task['hyhead:test'].invoke
        Rake::Task['hyhead:cucumber'].invoke
    end
    raise "test failures: #{error}" if error
  end

  
  desc "Easiest way to run rspec tests. Copies code to host plugins dir, loads fixtures, then runs specs - need to have jetty running."
  task :spec => "rspec:setup_and_run"
  
  namespace :rspec do
      
    desc "Run the hydra-head specs - need to have jetty running, test host set up and fixtures loaded."
    ENV['RAILS_ROOT'] = File.join(File.expand_path(File.dirname(__FILE__)),'..','tmp','test_app')
    RSpec::Core::RakeTask.new(:run) do |t|
      t.rspec_opts = "--colour"
      
      # pattern directory name defaults to ./**/*_spec.rb, but has a more concise command line echo
      t.pattern = File.join(File.expand_path(File.dirname(__FILE__)),'..','test_support','spec')
    end
    
    
    desc "Sets up test host, loads fixtures, then runs specs - need to have jetty running."
    task :setup_and_run => ["hyhead:setup_test_app"] do
			puts "Reloading fixtures"
      puts %x[rake hyhead:fixtures:refresh RAILS_ENV=test]
      Rake::Task["hyhead:rspec:run"].invoke
    end
        
  end

  
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../")
    doc_destination = File.join(project_root, 'doc')
    if !File.exists?(doc_destination) 
      FileUtils.mkdir_p(doc_destination)
    end

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = ['lib/**/*', project_root+"*", 'app/**/*']

      yt.options << "-m" << "textile"
      yt.options << "--protected"
      yt.options << "--no-private"
      yt.options << "-r" << "README.textile"
      yt.options << "-o" << "doc"
      yt.options << "--files" << "*.textile"
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end
  
  #
  # Cucumber
  #
  
  
  # desc "Easieset way to run cucumber tests. Sets up test host, refreshes fixtures and runs cucumber tests"
  # task :cucumber => "cucumber:setup_and_run"
  task :cucumber => "cucumber:run"
  

  namespace :cucumber do

    require 'cucumber/rake/task'

    ### Don't call this directly, use hyhead:cucumber:run
    Cucumber::Rake::Task.new(:cmd) do |t|
      t.cucumber_opts = "../../test_support/features --format pretty"
    end
   
    desc "Run cucumber tests for hyhead - need to have jetty running, test host set up and fixtures loaded."
    task :run => :set_test_host_path do
      Dir.chdir(TEST_HOST_PATH)
      puts "Running cucumber features in test host app"
      Rake::Task["hyhead:cucumber:cmd"].invoke
      FileUtils.cd('../../')
    end
 
  end
   
  
  
  #
  # Misc Tasks
  #
  
  desc "Creates a new test app"
  task :setup_test_app => [:set_test_host_path] do
    # Thor::Util.load_thorfile('tasks/test_app_builder.thor', nil, nil)
    # klass, task = Thor::Util.find_class_and_task_by_namespace("hydra:test_app_builder:build")
    # klass.start([task])
      path = TEST_HOST_PATH
      errors = []
      puts "Cleaning out test app path"
      %x[rm -fr #{path}]
      errors << 'Error removing test app' unless $?.success?

      FileUtils.mkdir_p(path)
      
      puts "Copying over .rvmrc file"
      FileUtils.cp("./test_support/etc/rvmrc",File.join(path,".rvmrc"))
      FileUtils.cd("tmp")
      system("source ./test_app/.rvmrc")
      
      puts "Installing rails, bundler and devise"
      %x[gem install --no-rdoc --no-ri 'rails' -v "<3.1"]
      %x[gem install --no-rdoc --no-ri 'bundler']
      
      puts "Generating new rails app"
      %x[rails new test_app]
      errors << 'Error generating new rails test app' unless $?.success?
      FileUtils.cd('test_app')
      
      FileUtils.rm('public/index.html')

      puts "Copying Gemfile from test_support/etc"
      FileUtils.cp('../../test_support/etc/Gemfile','./Gemfile')

      puts "Creating local vendor/cache dir and copying gems from hyhead-rails3 gemset"
      FileUtils.cp_r(File.join('..','..','vendor','cache'), './vendor')
      
      puts "Copying fixtures into test app spec/fixtures directory"
      FileUtils.mkdir_p( File.join('.','test_support') )
      FileUtils.cp_r(File.join('..','..','test_support','fixtures'), File.join('.','test_support','fixtures'))
      
      puts "Executing bundle install --local"
      puts %x[bundle install --local]
      errors << 'Error running bundle install in test app' unless $?.success?

      puts "Installing cucumber in test app"
      puts %x[rails g cucumber:install]
      errors << 'Error installing cucumber in test app' unless $?.success?

      puts "generating default blacklight install"
      puts %x[rails generate blacklight --devise]
      errors << 'Error generating default blacklight install' unless $?.success?
      
      puts "generating default hydra-head install"
      puts %x[rails generate hydra:head -df]  # using -f to force overwriting of solr.yml
      errors << 'Error generating default hydra-head install' unless $?.success?

      # set log_level to :warn in the test app's test environment. (:debug is too verbose)
      after = 'TestApp::Application.configure do'
      replace!( "#{path}/config/environments/test.rb",  /#{after}/, "#{after}\n    config.log_level = :warn\n")

      puts "Running rake db:migrate"
      %x[rake db:migrate]
      %x[rake db:test:prepare]
      raise "Errors: #{errors.join("; ")}" unless errors.empty?


    
    FileUtils.cd('../../')
    

  end
  
  task :set_test_host_path do
    TEST_HOST_PATH = File.join(File.expand_path(File.dirname(__FILE__)),'..','tmp','test_app')
  end
  
  #
  # Test
  #
  desc "Run tests against test app"
  task :test => [:spec, :cucumber]  do
    
  end

  # desc "Run tests against test app"
  # task :test => [:use_test_app]  do
  #   
  #   puts "Running rspec tests"
  #   puts %x[rake hyhead:spec]
  #   rspec_success = $?.success?

  #   puts "Running cucumber tests"
  #   puts %x[rake hyhead:cucumber]
  #   cucumber_success = $?.success?

  #   FileUtils.cd('../../')
  #   if rspec_success && cucumber_success
  #     puts "Completed test suite with no errors"
  #   else
  #     puts "Test suite encountered failures... check console output for details."
  #     fail
  #   end
  # end
  
  desc "Make sure the test app is installed, then run the tasks from its root directory"
  task :use_test_app => [:set_test_host_path] do
    Rake::Task['hyhead:setup_test_app'].invoke unless File.exist?(TEST_HOST_PATH)
    FileUtils.cd(TEST_HOST_PATH)
  end
end


        # Adds the content to the file.
        #
        def replace!(destination, regexp, string)
          content = File.binread(destination)
          content.gsub!(regexp, string)
          File.open(destination, 'wb') { |file| file.write(content) }
        end
