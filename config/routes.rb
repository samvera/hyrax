CurationConcerns::Engine.routes.draw do
  # mount BrowseEverything::Engine => '/remote_files/browse'
  resources :classify_concerns, only: [:new, :create]
end
