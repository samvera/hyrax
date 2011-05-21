require 'spec/rake/spectask'

namespace :hyhead do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do
    Rake::Task["hyhead:doc"].invoke

    require 'jettywrapper'
    jetty_params = {
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
      :quiet => false,
      :jetty_port => 8983,
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/solr'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/fedora/default'),
      :startup_wait => 20
      }

    # does this make jetty run in TEST environment???
    error = Jettywrapper.wrap(jetty_params) do
      system("rake hydra:default_fixtures:refresh environment=test")
      Rake::Task["hyhead:spec"].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc "Copy code to host plugins dir then run specs - need to have jetty running and fixtures loaded."
  task :spec => [:remove_from_host_plugins_dir, :copy_to_host_plugins_dir, :rspec] do
  end

  desc "Run the hydra-head specs - need to have jetty running and fixtures loaded."
  Spec::Rake::SpecTask.new(:rspec) do |t|
#    t.spec_opts = ['--options', "/spec/spec.opts"]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
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
      yt.files   = Dir.glob(File.join(project_root, '*.rb')) + 
                   Dir.glob(File.join(project_root, 'app', '**', '*.rb')) + 
                   Dir.glob(File.join(project_root, 'config', '**', '*.rb')) + 
                   Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   [ File.join(project_root, 'README.textile') ]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end
  
  desc "Copy the current plugin code into hydra-plugin_test_host/vendor/plugins/hydra-head"
  task :copy_to_host_plugins_dir => [:set_test_host_path] do
    excluded = [".", "..", ".git", ".gitignore", ".gitmodules", ".rvmrc", ".yardoc", "coverage", "coverage.data", "doc", "tmp", "hydra-plugin_test_host", "jetty"]
    plugin_dir = "#{TEST_HOST_PATH}/vendor/plugins/hydra-head"
    FileUtils.mkdir_p(plugin_dir)
    
    puts "Copying plugin files to #{plugin_path}:"

    Dir.foreach(".") do |fn| 
      unless excluded.include?(fn)
        puts " #{fn}"
        FileUtils.cp_r(fn, "#{plugin_dir}/#{fn}", :remove_destination=>true)
      end
    end
  end
  
  desc "Remove hydra-plugin_test_host/vendor/plugins/hydra-head"
  task :remove_from_host_plugins_dir => [:set_test_host_path] do
    plugin_dir = "#{TEST_HOST_PATH}/vendor/plugins/hydra-head"    
    puts "Emptying out #{plugin_dir}"
    %x[rm -rf #{plugin_dir}]
  end
  
  desc "Copy current contents of the features directory into hydra-plugin_test_host/features"
  task :copy_features_to_host => [:set_test_host_path] do
    features_dir = 
    excluded = [".", ".."]
    FileUtils.mkdir_p(features_dir)
    
    puts "Copying features to #{TEST_HOST_PATH}/features"
    
    %x[cp -R features #{TEST_HOST_PATH}]
  end
  
  desc "Copy current contents of the features directory into hydra-plugin_test_host/features"
  task :remove_features_from_host => [:set_test_host_path] do
    features_dir = "#{TEST_HOST_PATH}/features"
    puts "Emptying out #{features_dir}"
    %x[rm -rf #{features_dir}]
  end
  
  
  task :set_test_host_path do
    TEST_HOST_PATH = "hydra-plugin_test_host"
  end
  
  desc "Run cucumber tests for hyhead"
  task :cucumber => [:set_test_host_path] do
    Rake::Task["hyhead:remove_features_from_host"].invoke
    Rake::Task["hyhead:copy_features_to_host"].invoke
    Dir.chdir(TEST_HOST_PATH)
    puts "Running cucumber features in test host app"
    puts %x[cucumber features]
  end

end