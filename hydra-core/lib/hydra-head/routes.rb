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
      [:assets_with_all_nested_routes]
    end

    module RouteSets
      def assets_with_all_nested_routes
        add_routes do |options|
          namespace :hydra do
            resources :file_assets
            resources :assets do 
              resources :file_assets
            end
          end
        end
      end
    end

    include RouteSets

  end
end
