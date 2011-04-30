require "active-fedora"

module Hydra
  module Head
    # require 'hydra-head/engine' if defined?(Rails)
    require 'hydra-head/version' 
  end
end
Dir[File.join(File.dirname(__FILE__), "hydra", "**", "*.rb")].each {|f| require f}
require "hydra"
require "stanford_blacklight_extensions"
require "blacklight"
Dir[File.join(File.dirname(__FILE__), "blacklight", "*.rb")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "mediashelf", "*.rb")].each {|f| require f}
