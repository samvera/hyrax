CurationConcerns::Engine.routes.draw do
  get 'single_use_link/show/:id' => 'single_use_links_viewer#show', as: :show_single_use_link
  get 'single_use_link/download/:id' => 'single_use_links_viewer#download', as: :download_single_use_link
  get 'single_use_link/generate_download/:id' => 'single_use_links#new_download', as: :generate_download_single_use_link
  get 'single_use_link/generate_show/:id' => 'single_use_links#new_show', as: :generate_show_single_use_link

  # mount BrowseEverything::Engine => '/remote_files/browse'
  resources :classify_concerns, only: [:new, :create]
end
