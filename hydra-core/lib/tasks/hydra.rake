require 'active_fedora/rake_support'

namespace :hydra do
  desc "Start a solr, fedora and rails instance"
  task :server do
    with_server(ENV['RAILS_ENV'] || 'development') do
      puts "Fedora: #{ActiveFedora.config.credentials[:url]}"
      puts "Solr..: #{ActiveFedora.solr_config[:url]}"
      begin
        if ENV['SKIP_RAILS']
          puts "^C to exit"
          sleep
        else
          # If HOST specified, bind to that IP with -b
          server_options = " -b #{ENV['HOST']}" if ENV['HOST']
          IO.popen("rails server#{server_options}") do |io|
            io.each do |line|
              puts line
            end
          end
        end
      rescue Interrupt
        puts "Stopping server"
      end
    end
  end

  desc "Start solr and fedora instances for tests"
  task :test_server do
    ENV['RAILS_ENV'] = 'test'
    ENV['SKIP_RAILS'] = 'true'
    Rake::Task['hydra:server'].invoke
  end
end
