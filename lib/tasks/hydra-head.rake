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
  


  desc "Run the hydra-head specs"
  Spec::Rake::SpecTask.new(:spec) do |t|
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

end