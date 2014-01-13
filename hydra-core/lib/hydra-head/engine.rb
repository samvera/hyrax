require "rails"
module HydraHead
  class Engine < Rails::Engine
    # Config defaults
    config.mount_at = '/'

    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
    )
    
    # Load rake tasks
    rake_tasks do
      Dir.glob(File.join(File.expand_path('../', File.dirname(__FILE__)),'railties', '*.rake')).each do |railtie|
        load railtie
      end
    end
  end 
end
