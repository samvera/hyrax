require 'active_fedora/rake_support'

namespace :hydra do
  desc "Start a solr, fedora and rails instance"
  task :server do
    with_server('development',
                fcrepo_port: ENV.fetch('FCREPO_PORT', '8984'),
                solr_port: ENV.fetch('SOLR_PORT', '8983')) do
      IO.popen('rails server') do |io|
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
end
