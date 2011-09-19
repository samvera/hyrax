# -*- encoding : utf-8 -*-
module HydraHead
  class Routes

    def initialize(router, options)
      @router = router
      @options = options
    end

    def draw
      route_sets.each do |r|
        self.send(r)
      end
    end

    protected

    def add_routes &blk
      @router.instance_exec(@options, &blk)
    end

    def route_sets
      (@options[:only] || default_route_sets) - (@options[:except] || [])
    end

    def default_route_sets
      #[:file_assets, :assets, :downloads, :contributors, :grants, :permissions, :superuser,:catalog, :get]
      [:get, :catalog, :superuser, :permissions, :assets_with_all_nested_routes]
    end

    module RouteSets


      def assets_with_all_nested_routes
        add_routes do |options|
          resources :file_assets
          match "withdraw", :to => "assets#withdraw", :as => "withdraw"   
          resources :assets do 
            # this is to remove documents from SOLR but not from Fedora.
            resources :contributors, :only=>[:new,:create]
            match '/contributors', :to => 'contributors#update', :as => 'update_contributors'
            match 'contributors/:contributor_type/:index', :to => 'contributors#show', :as => 'contributor', :via => 'get'
            match 'contributors/:contributor_type/:index', :to => 'contributors#destroy', :as => 'connect',  :via => 'delete'
            resources :file_assets
            resources :downloads, :only=>[:index]
            resources :grants, :only=>[:new,:create]
            resources :permissions
            # Allow updates to assets/:asset_id/permissions (no :id necessary)
            match '/permissions', :to => 'permissions#update', :as => 'update_group_permissions'            
          end
          match "generic_contents_object/content/:container_id", :to=>"generic_content_objects#create", :as=>'generic_content_object',  :via => 'post'            
        end
      end
      
      def permissions
        add_routes do |options|
          resources :permissions
        end
      end


      def superuser
        add_routes do |options|
          match 'superuser', :to => 'user_sessions#superuser', :as => 'superuser'
        end
      end

      def catalog
        add_routes do |options|
          match 'catalog/:id/edit', :to => 'catalog#edit', :as => 'edit_catalog'
          # The delete method renders a confirmation page with a button to submit actual destroy request
          match 'catalog/:id/delete', :to => 'catalog#delete', :as => 'delete_catalog'
	  ### The rest of these routes are defined in blacklight
          #resources :catalog, :id=> /.+/
         # resources :catalog, :only => [:index, :show], :controller => "hydra_head/catalog", :path_prefix => HydraHead::Engine.config.mount_at, :as => "hydra_head", :id=> /.+/
          #match 'catalog/:id', :to => "hydra_head/catalog#show", :path_prefix => HydraHead::Engine.config.mount_at, :as => "catalog", :id => /.+/
          #match 'catalog/:id', :to => "hydra_head/catalog#show", :id => /.+/
          # match 'about', :to => 'catalog#about', :as => 'about'
        end
      end


      def get
        add_routes do |options|
          resources :get, :only=>:show 
        end
      end


    end
    include RouteSets

#match 'generic_contents_object/content/:container_id', :to => 'generic_content_objects#create', :as => 'generic_content_object', :via => :post
  end
end
