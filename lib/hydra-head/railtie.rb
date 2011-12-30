require 'active-fedora'
require 'rails'

module HydraHead
  class Railtie < Rails::Railtie
    initializer "hydra-head.configure_rails_initialization" do
      ActiveFedora.init
    end
  end
end

