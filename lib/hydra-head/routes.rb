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
      [:catalog, :superuser, :permissions, :assets_with_all_nested_routes]
    end

    module RouteSets


      def assets_with_all_nested_routes
        add_routes do |options|
          match "withdraw", :to => "assets#withdraw", :as => "withdraw"   
          namespace :hydra do
            resources :file_assets
            resources :assets do 
              # this is to remove documents from SOLR but not from Fedora.
              resources :contributors, :only=>[:new,:create]
              match '/contributors', :to => 'contributors#update', :as => 'update_contributors'
              # We would need to include the rails JS files (or implement our own) if we want this to work w/ DELETE because we delete from a link not a button.
              #match 'contributors/:contributor_type/:index', :to => 'contributors#destroy', :as => 'connect',  :via => 'delete'
              match 'contributors/:contributor_type/:index', :to => 'contributors#destroy', :as => 'connect'
              # There is no ContributorsController#show
              match 'contributors/:contributor_type/:index', :to => 'contributors#show', :as => 'contributor', :via => 'get'
              resources :file_assets
              resources :downloads, :only=>[:index]
              resources :grants, :only=>[:new,:create]
              resources :permissions
              # Allow updates to assets/:asset_id/permissions (no :id necessary)
              match '/permissions', :to => 'permissions#update', :as => 'update_group_permissions'            
            end
          end
          match "generic_contents_object/content/:container_id", :to=>"generic_content_objects#create", :as=>'generic_content_object',  :via => 'post'            
        end
      end
      
      def permissions
        add_routes do |options|
          namespace :hydra do
            resources :permissions
          end
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
        end
      end




    end
    include RouteSets

#match 'generic_contents_object/content/:container_id', :to => 'generic_content_objects#create', :as => 'generic_content_object', :via => :post
  end
end
