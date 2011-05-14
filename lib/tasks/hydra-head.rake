namespace :hyhead do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do
    require 'jettywrapper'
    jetty_params = {
      :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
      :quiet => false,
      :jetty_port => 8983,
      :solr_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/solr'),
      :fedora_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty/fedora/default'),
      :startup_wait => 30
      }

    # does this make jetty run in TEST environment???
    error = Jettywrapper.wrap(jetty_params) do
      system("rake hydra:default_fixtures:refresh environment=test")
      Rake::Task["hyhead:doc"].invoke
      Rake::Task["hyhead:spec"].invoke
    end
    raise "test failures: #{error}" if error
  end


  desc "Execute Continuous Integration build (docs, tests with coverage) without jetty wrapper"
  task :orig_ci do
    Rake::Task["hyhead:doc"].invoke
    Rake::Task["hyhead:spec"].invoke
  end
  
  desc "Copy code to host plugins dir then run spec"
  task :spec => [:remove_from_host_plugins_dir, :copy_to_host_plugins_dir, :rspec] do
  end

  desc "Run the hydra-head specs"
  Spec::Rake::SpecTask.new(:rspec) do |t|
#    t.spec_opts = ['--options', "/spec/spec.opts"]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    end
  end
  
  desc "Generate the hydra-head documentation (using yard)"
  task :doc do
    begin
      require 'yard'
      require 'yard/rake/yardoc_task'
      project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
      doc_destination = File.join(project_root, 'doc')

      YARD::Rake::YardocTask.new(:doc) do |yt|
        yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                     [ File.join(project_root, 'README.textile') ]
        yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
      end
    rescue LoadError
      desc "Generate YARD Documentation"
      task :doc do
        abort "Please install the YARD gem to generate rdoc."
      end
    end
  end
  
  desc "Copy code to host plugins dir then run spec"
  task :spec_with_copy => [:copy_to_host_plugins_dir, :spec] do
  end
  
  desc "Copy the current plugin code into hydra-plugin_test_host/vendor/plugins/hydra-head"
  task :copy_to_host_plugins_dir do
    excluded = [".", "..", ".git", ".gitignore", ".gitmodules", ".rvmrc", "coverage", "coverage.data", "tmp", "hydra-plugin_test_host", "jetty"]
    plugin_dir = "hydra-plugin_test_host/vendor/plugins/hydra-head"
    FileUtils.mkdir_p(plugin_dir)
    
    puts "Copying plugin files to #{plugin_dir}:"

    Dir.foreach(".") do |fn| 
      unless excluded.include?(fn)
        puts " #{fn}"
        FileUtils.cp_r(fn, "#{plugin_dir}/#{fn}", :remove_destination=>true)
      end
    end
  end
  
  desc "Remove hydra-plugin_test_host/vendor/plugins/hydra-head"
  task :remove_from_host_plugins_dir do
    plugin_path = "hydra-plugin_test_host/vendor/plugins/hydra-head"
    puts "Emptying out #{plugin_path}"
    %x[rm -rf #{plugin_path}]
  end

end