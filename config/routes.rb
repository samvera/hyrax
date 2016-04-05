Sufia::Engine.routes.draw do
  # Downloads controller route
  resources :homepage, only: 'index'

  # Route the home page as the root
  root to: 'sufia/homepage#index'

  # Handle routes that existed in Sufia < 7
  #   e.g. https://scholarsphere.psu.edu/files/gm80hv36p
  get '/files/:id', to: redirect('/concern/generic_works/%{id}')

  post '/uploads', to: 'sufia/uploads#create'
  # This is a hack that is required because the rails form the uploader is on
  # sets the _method parameter to patch when the work already exists.
  # Eventually it would be good to update the javascript so that it doesn't
  # submit the form, just the file and always uses POST.
  patch '/uploads', to: 'sufia/uploads#create'

  match 'batch_edits/clear' => 'batch_edits#clear', as: :batch_edits_clear, via: [:get, :post]

  # Notifications route for catalog index view
  get 'users/notifications_number' => 'users#notifications_number', as: :user_notify
  resources :batch_uploads, only: [:new, :create], controller: 'sufia/batch_uploads'

  # File Set routes
  namespace :curation_concerns, path: :concern do
    resources :file_sets, only: [] do
      resource :audit, only: [:create]
      member do
        get 'stats'
      end
    end
    resources :generic_works
  end

  resources :files, only: [] do
    member do
      get :citation, controller: :citations, action: :file, as: :citations
      get :stats, controller: :stats, action: :file, as: :stats
    end
  end

  # Generic work routes
  resources :works, only: [] do
    member do
      resources :transfers, as: :generic_work_transfers, only: [:new, :create]
      resource :featured_work, only: [:create, :destroy]
      get :citation, controller: :citations, action: :work, as: :citations
      get :stats, controller: :stats, action: :work, as: :stats
    end
  end

  # Depositors routes for proxy deposit
  post 'users/:user_id/depositors' => 'depositors#create', as: 'user_depositors'
  delete 'users/:user_id/depositors/:id' => 'depositors#destroy', as: 'user_depositor'

  resources :featured_work_lists, path: 'featured_works', only: :create

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

  # Routes for user's works, collections, highlights and shares
  # Preserves existing behavior by maintaining paths to /dashboard
  # Routes actions to the various My controllers
  scope :dashboard do
    get '/works',             controller: 'my/works', action: :index, as: 'dashboard_works'
    get '/works/page/:page',  controller: 'my/works', action: :index
    get '/works/facet/:id',   controller: 'my/works', action: :facet, as: 'dashboard_works_facet'

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

  # Contact form routes
  post 'contact' => 'contact_form#create', as: :contact_form_index
  get 'contact' => 'contact_form#new'

  # Permissions routes
  namespace :curation_concerns, path: :concern do
    resources(:permissions, only: []) do
      member do
        get :confirm
        post :copy
      end
    end
  end

  # API routes
  if Sufia.config.arkivo_api
    namespace :api do
      if defined?(Sufia::ArkivoConstraint)
        constraints Sufia::ArkivoConstraint do
          resources :items, except: [:index, :edit, :new], defaults: { format: :json }
        end
      end

      get 'zotero' => 'zotero#initiate', as: :zotero_initiate
      get 'zotero/callback' => 'zotero#callback', as: :zotero_callback
    end
  end

  # Collections routes
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

  if defined?(Sufia::StatsAdmin)
    namespace :admin do
      constraints Sufia::StatsAdmin do
        get 'stats' => 'stats#index', as: :stats
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
