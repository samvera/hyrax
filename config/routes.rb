CurationConcerns::Engine.routes.draw do
  get 'single_use_link/show/:id' => 'single_use_links_viewer#show', as: :show_single_use_link
  get 'single_use_link/download/:id' => 'single_use_links_viewer#download', as: :download_single_use_link
  post 'single_use_link/generate_download/:id' => 'single_use_links#create_download', as: :generate_download_single_use_link
  post 'single_use_link/generate_show/:id' => 'single_use_links#create_show', as: :generate_show_single_use_link
  get 'single_use_link/generated/:id' => 'single_use_links#index', as: :generated_single_use_links
  delete 'single_use_link/:id/delete/:link_id' => 'single_use_links#destroy', as: :delete_single_use_link

  # mount BrowseEverything::Engine => '/remote_files/browse'
  resources :classify_concerns, only: [:new, :create]

  resources :users, only: [] do
    resources :operations, only: [:index, :show]
  end
end
