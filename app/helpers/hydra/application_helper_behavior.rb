#require "hydra_helper"
module Hydra
  module ApplicationHelperBehavior
    include HydraHelper
    
    def application_name
      'A Hydra Head'
    end
  end
end
