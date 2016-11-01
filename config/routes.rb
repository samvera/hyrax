Sufia::Engine.routes.draw do
  # Downloads controller route
  resources :homepage, only: 'index'

  # Route the home page as the root
  root to: 'sufia/homepage#index'

  # Handle routes that existed in Sufia < 7
  #   e.g. https://scholarsphere.psu.edu/files/gm80hv36p
  get '/files/:id', to: redirect('/concern/generic_works/%{id}')

  # ResourceSync routes
  get '/.well-known/resourcesync' => 'sufia/resource_sync#source_description', as: :source_description
  get '/capabilitylist' => 'sufia/resource_sync#capability_list', as: :capability_list
  get '/resourcelist' => 'sufia/resource_sync#resource_list', as: :resource_list

  delete '/uploads/:id', to: 'sufia/uploads#destroy', as: :sufia_uploaded_file
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
      resources :transfers, as: :work_transfers, only: [:new, :create]
      resource :featured_work, only: [:create, :destroy]
      get :citation, controller: :citations, action: :work, as: :citations
      get :stats, controller: :stats, action: :work, as: :stats
      post 'trophy' => 'sufia/trophies#toggle_trophy' # used by sufia/trophy.js
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

  # User profile
  resources :users, only: [:index, :show, :edit, :update], as: :profiles

  resources :users, only: [] do
    resources :operations, only: [:index, :show], controller: 'sufia/operations'
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

  # Contact form routes
  post 'contact' => 'contact_form#create', as: :contact_form_index
  get 'contact' => 'contact_form#new'

  # Permissions routes
  namespace :curation_concerns, path: :concern do
    resources :permissions, only: [] do
      member do
        get :confirm
        post :copy
        get :confirm_access
        post :copy_access
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

  resources :admin_sets, controller: 'sufia/admin_sets'

  resource :admin, controller: 'sufia/admin', only: [:show]
  scope 'admin', module: 'sufia/admin', as: 'admin' do
    resources :admin_sets do
      resource :permission_template
    end
    resources :permission_template_accesses, only: :destroy
    resource 'stats', only: [:show]
    resources :features, only: [:index] do
      resources :strategies, only: [:update, :destroy]
    end
  end

  resources :content_blocks, only: ['create', 'update']
  get 'featured_researchers' => 'content_blocks#index', as: :featured_researchers
  post '/tinymce_assets' => 'tinymce_assets#create'

  get 'about' => 'pages#show', id: 'about_page'

  # Static page routes
  %w(help terms zotero mendeley agreement versions).each do |action|
    get action, controller: 'static', action: action, as: action
  end
end
