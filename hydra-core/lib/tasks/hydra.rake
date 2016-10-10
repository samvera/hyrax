require 'active_fedora/rake_support'

namespace :hydra do
  desc "Start a solr, fedora and rails instance"
  task :server do
    with_server('development') do
      # If HOST specified, bind to that IP with -b
      server_options = " -b #{ENV['HOST']}" if ENV['HOST']
      IO.popen("rails server#{server_options}") do |io|
        begin
          io.each do |line|
            puts line
          end
        rescue Interrupt
          puts "Stopping server"
        end
      end
    end
  end

  desc "Start solr and fedora instances for tests"
  task :test_server do
    with_server('test') do
      begin
        sleep
      rescue Interrupt
        puts "Stopping server"
      end
    end
  end
end
