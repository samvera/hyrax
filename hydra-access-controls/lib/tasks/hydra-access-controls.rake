namespace "hydra-access" do
  desc "Run Continuous Integration"
  task "ci" do
    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config.merge(
        {:jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
          :startup_wait => 15, 
          :jetty_port => ENV['TEST_JETTY_PORT'] || 8983
        }
    )
    Rake::Task['jetty:config'].invoke
    error = nil
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task['spec'].invoke
    end
    raise "test failures: #{error}" if error
  end
end
