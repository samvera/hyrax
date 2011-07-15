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
      [:file_assets, :assets, :downloads, :contributors, :grants, :permissions, :superuser, :asset_file_assets, :catalog, :get]
    end

    module RouteSets

      def file_assets
        add_routes do |options|
          resources :file_assets
        end
      end

      def assets
        add_routes do |options|
          resources :assets
          # this is to remove documents from SOLR but not from Fedora.
          match "withdraw", :to => "assets#withdraw", :as => "withdraw"   
        end
      end

      def downloads
        add_routes do |options|
          resources :assets do
            resources :downloads, :only=>[:index]
          end
        end
      end

      def contributors
        add_routes do |options|
          resources :assets do
            resources :contributors, :only=>[:new,:create]
          end
          match 'assets/:asset_id/contributors/:contributor_type/:index', :to => 'contributors#show', :as => 'asset_contributor', :via => 'get'
          match 'assets/:asset_id/contributors/:contributor_type/:index', :to => 'contributors#destroy', :as => 'connect',  :via => 'delete'
        end
      end

      def grants
        add_routes do |options|
          resources :assets do
            resources :grants, :only=>[:new,:create]
          end
        end
      end

      def permissions
        add_routes do |options|
          resources :assets do
            resources :permissions
          end
          # Allow updates to assets/:asset_id/permissions (no :id necessary)
          match 'assets/:asset_id/permissions', :to => 'permissions#update', :as => 'update_group_permissions'
        end
      end
      def superuser
        add_routes do |options|
          match 'superuser', :to => 'user_sessions#superuser', :as => 'superuser'
        end
      end

      def asset_file_assets
        add_routes do |options|
          resources :assets do
            resources :file_assets
          end
        end
      end

      def catalog
        add_routes do |options|
          resources :catalog, :only => [ :index, :show ], :controller => "hydra_head/catalog", :path_prefix => HydraHead::Engine.config.mount_at, :as => "hydra_head_"
          #resources :catalog, :only => [:edit, :delete]
          match 'catalog/:id/edit', :to => 'catalog#edit', :as => 'edit_catalog'
          match 'catalog/:id/delete', :to => 'catalog#delete', :as => 'delete_catalog'
          match 'about', :to => 'catalog#about', :as => 'about'
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
