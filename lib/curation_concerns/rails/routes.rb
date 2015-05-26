module ActionDispatch::Routing
  class Mapper

    def curation_concerns_curation_concerns
      resources :downloads, only: :show
      namespace :curation_concern, path: :concern do
        CurationConcerns.configuration.registered_curation_concern_types.map(&:tableize).each do |curation_concern_name|
          namespaced_resources curation_concern_name, except: [:index]
        end
        resources :permissions, only: [] do
          member do
            get :confirm
            post :copy
          end
        end
        resources :linked_resources, only: [:new, :create], path: 'container/:parent_id/linked_resources'
        resources :linked_resources, only: [:show, :edit, :update, :destroy]
        resources :generic_files, only: [:new, :create], path: 'container/:parent_id/generic_files'
        resources :generic_files, only: [:show, :edit, :update, :destroy] do
          member do
            get :versions
            put :rollback
          end
        end
      end
    end

    # Used in conjunction with Hydra::Collections::Engine routes.
    # Adds routes for doing paginated searches within a collection's contents
    # @example in routes.rb:
    #     mount Hydra::Collections::Engine => '/'
    #     curation_concerns_collections
    def curation_concerns_collections
      resources :collections, only: :show do
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
    # Namespaces routes appropriately
    # @example route_namespaced_target("curation_concerns/generic_work") is equivalent to
    #   namespace "curation_concerns" do
    #     resources "generic_work", except: [:index]
    #   end
    def namespaced_resources(target, opts={})
      if target.include?("/")
        the_namespace = target[0..target.index("/")-1]
        new_target = target[target.index("/")+1..-1]
        namespace the_namespace do
          namespaced_resources(new_target, opts)
        end
      else
        resources target, opts
      end
    end
  end
end
