# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Hydra 
# A singleton class for starting/stopping a Jetty server for testing purposes
# The behavior of TestSolrServer can be modified prior to start() by changing 
# port, solr_home, and quiet properties.
#
# This class is based on Blacklight's TestSolrServer
class TestingServer
  require 'singleton'
  include Singleton
  require 'win32/process' if RUBY_PLATFORM =~ /mswin32/
  attr_accessor :port, :jetty_home, :solr_home, :quiet, :fedora_home, :base_path

  # configure the singleton with some defaults
  def initialize(params = {})
    @pid = nil
    if defined?(Rails.root)
      @base_path = Rails.root
    else
      @base_path = "."
    end
  end

  class << self
    def configure(params = {})
      hydra_server = self.instance
      hydra_server.quiet = params[:quiet].nil? ? true : params[:quiet]
      if defined?(Rails.root)
        base_path = Rails.root
      else
        base_path = "."
      end
      hydra_server.jetty_home = params[:jetty_home] || File.expand_path(File.join(base_path, 'jetty'))
      hydra_server.solr_home = params[:solr_home]  || File.join( hydra_server.jetty_home, "solr")
      hydra_server.fedora_home = params[:fedora_home] || File.join( hydra_server.jetty_home, "fedora","default")
      hydra_server.port = params[:jetty_port] || 8888
      return hydra_server
    end
    
    def wrap(params = {})
      error = false
      hydra_server = self.configure(params)
      begin
        puts "starting Hydra jetty server on #{RUBY_PLATFORM}"
        hydra_server.start
        sleep params[:startup_wait] || 5
        yield
      rescue
        error = true
      ensure
        puts "stopping Hydra jetty server"
        hydra_server.stop
      end

      return error
    end
  end

  def jetty_command
    "java -Djetty.port=#{@port} -Dsolr.solr.home=#{@solr_home} -Dfedora.home=#{@fedora_home} -jar start.jar"
  end
 
  def start
    puts "jetty_home: #{@jetty_home}"
    puts "solr_home: #{@solr_home}"
    puts "fedora_home: #{@fedora_home}"
    puts "jetty_command: #{jetty_command}"
    if pid
      begin
        Process.kill(0,pid)
        raise("Server is already running with PID #{pid}")
      rescue Errno::ESRCH
        STDERR.puts("Removing stale PID file at #{pid_path}")
        File.delete(pid_path)
      end
    end
    Dir.chdir(@jetty_home) do
      self.send "#{platform}_process".to_sym
    end
    mkpath(pid_dir) unless File.directory?(pid_dir)
    begin
      f = File.new(pid_path,  "w")
    rescue Errno::ENOENT, Errno::EACCES
      f = File.new(File.join(@base_path,'tmp',pid_file),"w")
    end
    f.puts "#{@pid}"
    f.close
  end
  
  def stop
    puts "stopping"
    if pid
      begin
        self.send "#{platform}_stop".to_sym
      rescue Errno::ESRCH
        STDERR.puts("Removing stale PID file at #{pid_path}")
      end
      FileUtils.rm(pid_path)
    end
  end
  
  def win_process
    @pid = Process.create(
          :app_name         => jetty_command,
          :creation_flags   => Process::DETACHED_PROCESS,
          :process_inherit  => false,
          :thread_inherit   => true,
          :cwd              => "#{@jetty_home}"
       ).process_id
  end

  def platform
    case RUBY_PLATFORM
    when /mswin32/
      return 'win'
    else
      return 'nix'
    end
  end

  def nix_process
    @pid = fork do
      STDERR.close if @quiet
      exec jetty_command
    end
  end

  # stop a running solr server
  def win_stop
    Process.kill(1, @pid)
  end

  def nix_stop
    Process.kill('TERM',pid)
  end

  def pid_path
    File.join(pid_dir, pid_file)
  end

  def pid_file
    @pid_file || 'hydra-jetty.pid'
  end

  def pid_dir
    File.expand_path(@pid_dir || File.join(@base_path,'tmp','pids'))
  end

  def pid
    @pid || File.open( pid_path ) { |f| return f.gets.to_i } if File.exist?(pid_path)
  end

end # class TestingServer
end # module Hydra

# 
# puts "hello"
# SOLR_PARAMS = {
#   :quiet => ENV['SOLR_CONSOLE'] ? false : true,
#   :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('../../jetty'),
#   :jetty_port => ENV['SOLR_JETTY_PORT'] || 8888,
#   :solr_home => ENV['SOLR_HOME'] || File.expand_path('test')
# }
# 
# # wrap functional tests with a test-specific Solr server
# got_error = TestSolrServer.wrap(SOLR_PARAMS) do
#   puts `ps aux | grep start.jar` 
# end
# 
# raise "test failures" if got_error
# 
