require 'rspec/core/rake_task'
desc "run the hydra-core gem spec"
gem_home = File.expand_path('../../../../..', __FILE__)
RSpec::Core::RakeTask.new(:myspec) do |t|
  t.rspec_opts = ["--colour", '--backtrace', "--default-path #{gem_home}"]
  t.ruby_opts = "-I#{gem_home}/spec"
end
