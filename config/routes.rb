Worthwhile::Engine.routes.draw do
  # mount BrowseEverything::Engine => '/remote_files/browse'
  scope module: 'curate' do
    resources 'collections' do
      collection do
        get :add_member_form
        put :add_member
        put :remove_member
      end
    end
  end
  resources :downloads, only: [:show]

  namespace :curation_concern, path: :concern do
    Worthwhile.configuration.registered_curation_concern_types.map(&:tableize).each do |container|
      resources container, except: [:index]
    end
    resources( :permissions, only:[]) do
      member do
        get :confirm
        post :copy
      end
    end
  #   resources( :linked_resources, only: [:new, :create], path: 'container/:parent_id/linked_resources')
  #   resources( :linked_resources, only: [:show, :edit, :update, :destroy])
    resources( :generic_files, only: [:new, :create], path: 'container/:parent_id/generic_files')
    resources( :generic_files, only: [:show, :edit, :update, :destroy]) do
      member do
        get :versions
        put :rollback
      end
    end
  end

  resources :classify_concerns, only: [:new, :create]
end
