Sufia::Engine.routes.draw do
  # Downloads controller route
  resources :homepage, only: 'index'

  # Route the home page as the root
  root to: 'homepage#index'

  get 'single_use_link/generate_download/:id' => 'single_use_links#new_download', as: :generate_download_single_use_link
  get 'single_use_link/generate_show/:id' => 'single_use_links#new_show', as: :generate_show_single_use_link
  get 'single_use_link/show/:id' => 'single_use_links_viewer#show', as: :show_single_use_link
  get 'single_use_link/download/:id' => 'single_use_links_viewer#download', as: :download_single_use_link

  match 'batch_edits/clear' => 'batch_edits#clear', as: :batch_edits_clear, via: [:get, :post]

  # Notifications route for catalog index view
  get 'users/notifications_number' => 'users#notifications_number', as: :user_notify

  # File Set routes
  resources :file_sets, path: :files, except: :index do
    member do
      resource :featured_work, only: [:create, :destroy]
      get 'citation'
      get 'stats'
      post 'audit'
    end
  end

  # Generic work routes
  resources :generic_works, path: :works, except: :index do
    member do
      resources :transfers, as: :generic_work_transfers, only: [:new, :create]
    end
  end

  # GenericWorks
  get '/works/:id', controller: 'curation_concerns/generic_works', action: :show, as: 'sufia_works_generic_work'

  # Depositors routes for proxy deposit
  post 'users/:user_id/depositors' => 'depositors#create', as: 'user_depositors'
  delete 'users/:user_id/depositors/:id' => 'depositors#destroy', as: 'user_depositor'

  resources :featured_work_lists, path: 'featured_works', only: :create

  # Downloads controller route
  resources :downloads, only: 'show'

  # Messages
  resources :notifications, only: [:destroy, :index], controller: :mailbox do
    collection do
      delete 'delete_all'
    end
  end

  # User profile & follows
  resources :users, only: [:index, :show, :edit, :update], as: :profiles do
    member do
      post 'trophy' => 'users#toggle_trophy' # used by trophy.js
      post 'follow' => 'users#follow'
      post 'unfollow' => 'users#unfollow'
    end
  end

  # Dashboard page
  resources :dashboard, only: :index do
    collection do
      get 'activity', action: :activity, as: :dashboard_activity
      resources :transfers, only: [:index, :destroy] do
        member do
          put 'accept'
          put 'reject'
        end
      end
    end
  end

  # Routes for user's files, collections, highlights and shares
  # Preserves existing behavior by maintaining paths to /dashboard
  # Routes actions to the various My controllers
  scope :dashboard do
    get '/files',             controller: 'my/files', action: :index, as: 'dashboard_files'
    get '/files/page/:page',  controller: 'my/files', action: :index
    get '/files/facet/:id',   controller: 'my/files', action: :facet, as: 'dashboard_files_facet'

    get '/collections',             controller: 'my/collections', action: :index, as: 'dashboard_collections'
    get '/collections/page/:page',  controller: 'my/collections', action: :index
    get '/collections/facet/:id',   controller: 'my/collections', action: :facet, as: 'dashboard_collections_facet'

    get '/highlights',            controller: 'my/highlights', action: :index, as: 'dashboard_highlights'
    get '/highlights/page/:page', controller: 'my/highlights', action: :index
    get '/highlights/facet/:id',  controller: 'my/highlights', action: :facet, as: 'dashboard_highlights_facet'

    get '/shares',            controller: 'my/shares', action: :index, as: 'dashboard_shares'
    get '/shares/page/:page', controller: 'my/shares', action: :index
    get '/shares/facet/:id',  controller: 'my/shares', action: :facet, as: 'dashboard_shares_facet'
  end

  # advanced routes for advanced search
  get 'search' => 'advanced#index', as: :advanced

  # Authority vocabulary queries route
  get 'authorities/:model/:term' => 'authorities#query'

  # LDAP-related routes for group and user lookups
  get 'directory/user/:uid' => 'directory#user'
  get 'directory/user/:uid/:attribute' => 'directory#user_attribute'
  get 'directory/group/:cn' => 'directory#group', constraints: { cn: /.*/ }

  # Batch edit routes
  get 'batches/:id/edit' => 'batch#edit', as: :batch_edit
  post 'batches/:id' => 'batch#update', as: :batch_file_sets

  # Contact form routes
  post 'contact' => 'contact_form#create', as: :contact_form_index
  get 'contact' => 'contact_form#new'

  # Permissions routes
  namespace :curation_concern, path: :concern do
    resources(:permissions, only: []) do
      member do
        get :confirm
        post :copy
      end
    end
  end

  mount Hydra::Collections::Engine => '/'

  # Resque monitoring routes. Don't bother with this route unless Sufia::ResqueAdmin
  # has been defined in the initalizers.
  if defined?(Sufia::ResqueAdmin)
    namespace :admin do
      constraints Sufia::ResqueAdmin do
        mount Resque::Server, at: 'queues'
      end
    end
  end

  resources :content_blocks, only: ['create', 'update']
  get 'featured_researchers' => 'content_blocks#index', as: :featured_researchers
  post '/tinymce_assets' => 'tinymce_assets#create'

  get 'about' => 'pages#show', id: 'about_page'
  # Static page routes (workaround)
  get ':action' => 'static#:action', constraints: { action: /help|terms|zotero|mendeley|agreement|subject_libraries|versions/ }, as: :static

  # Single use link errors
  get 'single_use_link/not_found' => 'errors#single_use_error'
  get 'single_use_link/expired' => 'errors#single_use_error'

  # Catch-all (for routing errors)
  unless Rails.env.development? || Rails.env.test?
    match '*error' => 'errors#routing', via: [:get, :post]
  end
end
