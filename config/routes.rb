Rails.application.routes.draw do |map|

  mount_at = HydraHead::Engine.config.mount_at

  match mount_at => 'hydra_head/catalog#index'

  map.resources :catalog, :only => [ :index, :show ],
                          :controller => "hydra_head/catalog",
                          :path_prefix => mount_at,
                          :name_prefix => "hydra_head_"

end
