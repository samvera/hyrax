ActionController::Routing::Routes.draw do |map|
     map.resources :file_assets
          
     # This creates routes named asset_file_assets, new_asset_file_asset, etc.
     # The routes map to the :file_assets controller with the param :container_id 
     # which is then used within the controller to deal with parent - child relationships 
     # between Assets and the FileAssets inside them.
     map.resources :file_assets, :path_prefix => '/assets/:container_id', :name_prefix => "asset_"
     
     map.resources :assets do |assets|
       assets.resources :downloads, :only=>[:index]
       assets.resources :contributors, :only=>[:new,:create]
       assets.resources :grants, :only=>[:new,:create]       
       assets.resources :permissions
    end
    
    map.asset_contributor 'assets/:asset_id/contributors/:contributor_type/:index', :controller=>:contributors, :action=>:show, :conditions => { :method => :get }
    map.connect 'assets/:asset_id/contributors/:contributor_type/:index', :controller=>:contributors, :action=>:destroy, :conditions => { :method => :delete }
    
    map.asset_grant 'assets/:asset_id/grants/:grant_type/:index', :controller=>:grants, :action=>:show, :conditions => { :method => :get }
    map.connect 'assets/:asset_id/grants/:grant_type/:index', :controller=>:grants, :action=>:destroy, :conditions => { :method => :delete }
    
    # Allow updates to assets/:asset_id/permissions (no :id necessary)
    map.update_group_permissions 'assets/:asset_id/permissions', :controller=>:permissions, :action=>:update
    
    map.generic_content_object 'generic_contents_object/content/:container_id', :controller=>:generic_content_objects, :action=>:create, :conditions => {:method => :post}
end
