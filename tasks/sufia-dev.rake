require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'jettywrapper'
JETTY_ZIP_BASENAME = 'fedora-4/b4'
Jettywrapper.url = "https://github.com/projecthydra/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

require 'engine_cart/rake_task'

desc 'Spin up hydra-jetty and run specs'
task ci: ['engine_cart:generate', 'jetty:clean', 'sufia:jetty:config'] do
  puts 'running continuous integration'
  jetty_params = Jettywrapper.load_config
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end

EXTRA_GEMS =<<EOF
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'
gem 'active-fedora', github: 'projecthydra/active_fedora', branch: 'fedora-4'

gem 'ldp', github: 'cbeer/ldp'
gem 'hydra-head', github: 'projecthydra/hydra-head', branch: 'fedora-4'
gem 'hydra-collections', github: 'projecthydra-labs/hydra-collections', branch: 'fedora-4'
gem 'hydra-derivatives', github: 'projecthydra-labs/hydra-derivatives', branch: 'fedora-4'

EOF

namespace :engine_cart do
  desc 'Regenerate embedded app for testing'
  task regenerate: ['engine_cart:clean', 'engine_cart:generate']

  # we're adding some extra stuff into the gemfile beyond what engine_cart gives us by default
  task :inject_gemfile_extras do
    open(File.expand_path('Gemfile', EngineCart.destination), 'a') do |f|
      f.write EXTRA_GEMS
    end
  end
end
