Worthwhile::Engine.routes.draw do
  # mount BrowseEverything::Engine => '/remote_files/browse'
  resources :classify_concerns, only: [:new, :create]
  namespace :curation_concern, path: :concern do
    # Worthwhile.configuration.registered_curation_concern_types.map(&:tableize).each do |curation_concern_name|
    #   namespaced_resources curation_concern_name, except: [:index]
    # end
    resources( :permissions, only:[]) do
      member do
        get :confirm
        post :copy
      end
    end
  end
end
