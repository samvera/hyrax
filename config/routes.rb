Rails.application.routes.draw do |map|

  mount_at = HydraHead::Engine.config.mount_at

  match mount_at => 'hydra_head/catalog#index'

  resources :catalog, :only => [ :index, :show ],
                          :controller => "hydra_head/catalog",
                          :path_prefix => mount_at,
                          :as => "hydra_head_"

  resources :file_assets
          
   # This creates routes named asset_file_assets, new_asset_file_asset, etc.
   # The routes map to the :file_assets controller with the param :container_id 
   # which is then used within the controller to deal with parent - child relationships 
   # between Assets and the FileAssets inside them.
   

# resources :file_assets, :path_prefix => '/assets/:container_id', :name_prefix => "asset_"
   
  resources :assets do |assets|
    resources :downloads, :only=>[:index]
    resources :contributors, :only=>[:new,:create]
    resources :grants, :only=>[:new,:create]       
    resources :permissions
    resources :file_assets
  end

  match 'catalog/:id/edit', :to => 'catalog#edit', :as => 'edit_catalog'
  match 'catalog/:id/delete', :to => 'catalog#delete', :as => 'delete_catalog'
  match 'about', :to => 'catalog#about', :as => 'about'
  
  resources :user_sessions
  match 'logged_out', :to => 'user_sessions#logged_out', :as => 'logged_out'
  match 'superuser', :to => 'user_sessions#superuser', :as => 'superuser'
  
  resources :get, :only=>:show 
  
  # this is to remove documents from SOLR but not from Fedora.
  match "withdraw", :to => "assets#withdraw", :as => "withdraw" 
  
  match 'assets/:asset_id/contributors/:contributor_type/:index', :to => 'contributors#show', :as => 'asset_contributor', :conditions => { :method => :get }
  match 'assets/:asset_id/contributors/:contributor_type/:index', :to => 'contributors#destroy', :as => 'connect',  :conditions => { :method => :delete }
  
  # Allow updates to assets/:asset_id/permissions (no :id necessary)
  match 'assets/:asset_id/permissions', :to => 'permissions#update', :as => 'update_group_permissions'
  
  match 'generic_contents_object/content/:container_id', :to => 'generic_content_objects#create', :as => 'generic_content_object', :conditions => {:method => :post}
end
