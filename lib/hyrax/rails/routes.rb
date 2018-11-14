module ActionDispatch::Routing
  class Mapper
    # @yield If a block is passed it is yielded for each curation_concern
    # @example
    #   curation_concerns_basic_routes do
    #     concerns :exportable
    #   end
    def curation_concerns_basic_routes(&block)
      resources :upload_sets, only: [:edit, :update]

      namespace :hyrax, path: :concern do
        namespaced_resources 'workflow_actions', only: [:update]
        concerns_to_route.each do |curation_concern_name|
          namespaced_resources curation_concern_name, except: [:index], &block
          namespaced_resources curation_concern_name, only: [] do
            member do
              get :manifest
              get :file_manager
              get :inspect_work
            end
          end
        end

        resources :parent, only: [] do
          concerns_to_route.each do |curation_concern_name|
            namespaced_resources curation_concern_name, except: [:index], &block
          end
        end

        resources :parent, only: [] do
          resources :file_sets, only: [:show]
        end

        resources :permissions, only: [] do
          member do
            get :confirm
            post :copy
          end
        end
        resources :file_sets, only: [:show, :edit, :update, :destroy] do
          member do
            get :versions
            put :rollback
          end
        end
      end
    end

    private

      # routing namepace arguments, for using a path other than the default
      ROUTE_OPTIONS = { 'hyrax' => { path: :concern } }.freeze

      # Namespaces routes appropriately
      # @example namespaced_resources("hyrax/my_work") is equivalent to
      #   namespace "hyrax", path: :concern do
      #     resources "my_work", except: [:index]
      #   end
      def namespaced_resources(target, opts = {}, &block)
        if target.include?('/')
          the_namespace = target[0..target.index('/') - 1]
          new_target = target[target.index('/') + 1..-1]
          namespace the_namespace, ROUTE_OPTIONS.fetch(the_namespace, {}) do
            namespaced_resources(new_target, opts, &block)
          end
        else
          resources target, opts do
            yield if block_given?
          end
        end
      end

      # @return [Array<String>] the list of works to build routes for
      def concerns_to_route
        Hyrax.config.registered_curation_concern_types.map(&:tableize)
      end
  end
end
