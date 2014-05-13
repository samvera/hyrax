#Load blacklight which will give worthwhile views a higher preference than those in blacklight
require 'blacklight'
require 'sufia/models'  
require 'hydra-collections'

module Worthwhile
  class Engine < ::Rails::Engine
    isolate_namespace Worthwhile
    require 'breadcrumbs_on_rails'

    config.eager_load_paths += %W(
     #{config.root}/app/inputs
    )
    
    config.action_dispatch.rescue_responses["ActionController::RoutingError"] = :not_found
    config.action_dispatch.rescue_responses["ActiveFedora::ObjectNotFoundError"] = :not_found
    config.action_dispatch.rescue_responses["ActiveFedora::ActiveObjectNotFoundError"] = :not_found
    config.action_dispatch.rescue_responses["Hydra::AccessDenied"] = :unauthorized
    config.action_dispatch.rescue_responses["CanCan::AccessDenied"] = :unauthorized
    config.action_dispatch.rescue_responses["Rubydora::RecordNotFound"] = :not_found

    initializer 'worthwhile.initialize' do
      require 'worthwhile/rails/routes' 
    end
  end
end
