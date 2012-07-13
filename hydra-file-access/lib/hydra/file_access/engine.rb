module Hydra
  module FileAccess
    class Engine < Rails::Engine
      # Load rake tasks
      rake_tasks do
        # Dir.glob(File.join(File.expand_path('../', File.dirname(__FILE__)),'railties', '*.rake')).each do |railtie|
        #   load railtie
        # end
      end
    end 
  end
end
