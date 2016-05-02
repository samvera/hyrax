module ActionDispatch::Routing
  class Mapper
    # @yield If a block is passed it is yielded for each curation_concern
    # @example
    #   curation_concerns_basic_routes do
    #     concerns :exportable
    #   end
    def curation_concerns_basic_routes(&block)
      resources :downloads, only: :show
      resources :upload_sets, only: [:edit, :update]

      namespace :curation_concerns, path: :concern do
        concerns_to_route.each do |curation_concern_name|
          namespaced_resources curation_concern_name, except: [:index], &block
          namespaced_resources curation_concern_name, only: [] do
            member do
              get :file_manager
            end
          end
        end

        resources :permissions, only: [] do
          member do
            get :confirm
            post :copy
          end
        end
        resources :file_sets, only: [:new, :create], path: 'container/:parent_id/file_sets'
        resources :file_sets, only: [:show, :edit, :update, :destroy] do
          member do
            get :versions
            put :rollback
          end
        end
      end
    end

    # Adds routes for doing paginated searches within a collection's contents
    # @example in routes.rb:
    #     curation_concerns_collections
    def curation_concerns_collections
      resources :collections do
        member do
          get 'page/:page', action: :index
          get 'facet/:id', action: :facet, as: :dashboard_facet
        end
        collection do
          put '', action: :update
          put :remove_member
        end
      end
    end

    # kmr added :show to make tests pass
    def curation_concerns_embargo_management
      resources :embargoes, only: [:index, :edit, :destroy] do
        collection do
          patch :update
        end
      end
      resources :leases, only: [:index, :edit, :destroy] do
        collection do
          patch :update
        end
      end
    end

    private

      # routing namepace arguments, for using a path other than the default
      ROUTE_OPTIONS = { 'curation_concerns' => { path: :concern } }.freeze

      # Namespaces routes appropriately
      # @example namespaced_resources("curation_concerns/my_work") is equivalent to
      #   namespace "curation_concerns", path: :concern do
      #     resources "my_work", except: [:index]
      #   end
      def namespaced_resources(target, opts = {}, &block)
        if target.include?('/')
          the_namespace = target[0..target.index('/') - 1]
          new_target = target[target.index('/') + 1..-1]
          namespace the_namespace, ROUTE_OPTIONS.fetch(the_namespace, nil) do
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
        CurationConcerns.config.registered_curation_concern_types.map(&:tableize)
      end
  end
end
