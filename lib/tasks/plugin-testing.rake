require "fileutils"

unless defined?(Rails)
  desc 'Set up Rails environment using hydra-plugin_test_host.'
  task :environment do
    def apply_blacklight_config_to_host
      bl_config_src_path = File.join(File.dirname(__FILE__), "..", "..", "config", "initializers", "blacklight_config.rb")
      bl_config_dest_path = File.join(File.dirname(__FILE__), "..", "..","hydra-plugin_test_host", "config", "initializers", "blacklight_config.rb")
      # f = File.new(bl_config_path) 
      FileUtils.copy_file(bl_config_src_path, bl_config_dest_path)
    end

    apply_blacklight_config_to_host

    # Overrides require_plugin_dependency, pointing to plugins within dummy app
    # Original require_plugin_dependency method defined in init.rb
    def require_plugin_dependency(dependency_path)
      modified_path = File.join(File.dirname(__FILE__), "..", "..","hydra-plugin_test_host", dependency_path)
      p "(plugin-testing) Re-routing require path to: #{modified_path}"
      require_dependency modified_path
    end

    require File.dirname(__FILE__) + "/../../hydra-plugin_test_host/config/environment" unless defined?(RAILS_ROOT)

    # This ensures that the current plugin's models, helpers and controllers are loaded last
    Dir["app/helpers/*.rb"].each {|f| require f }
    Dir["app/models/*.rb"].each {|f| require f}
  end
end