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
      [:catalog, :assets]
    end
    
    module RouteSets
      def catalog
        add_routes do |options|
          resources :catalog, :only => [:edit]
        end
      end
      
      def assets
        add_routes do |options|
          resources :assets
        end
      end
      
    end
    include RouteSets
    
  end
end