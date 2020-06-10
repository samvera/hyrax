require 'rake'

module RakeHelper
  def load_rake_environment(files)
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::Task.define_task(:environment)
    files.each { |file| load file }
  end

  def run_task(task, arg = nil)
    capture_stdout_stderr do
      @rake[task].invoke(arg)
    end
  end

  # saves original $stdout in variable
  # set $stdout as local instance of StringIO
  # yields to code execution
  # returns the local instance of StringIO
  # resets $stdout to original value
  def capture_stdout_stderr
    out = StringIO.new
    err = StringIO.new
    $stdout = out
    $stderr = err
    begin
      yield
    rescue SystemExit => e
      puts "error = #{e.inspect}"
    end
    "Output: #{out.string}\n Errors:#{err.string}"
  ensure
    $stdout = STDOUT
    $stdout = STDERR
  end

  RSpec.configure do |config|
    config.include RakeHelper
  end
end
