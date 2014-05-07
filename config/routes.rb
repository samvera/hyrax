Sufia::Engine.routes.draw do

  # Downloads controller route
  resources :homepage, :only => "index"

  # Route the home page as the root
  root :to => "homepage#index"

  get 'single_use_link/generate_download/:id' => 'single_use_links#new_download', :as => :generate_download_single_use_link
  get 'single_use_link/generate_show/:id' => 'single_use_links#new_show', :as => :generate_show_single_use_link
  get 'single_use_link/show/:id' => 'single_use_links_viewer#show', :as => :show_single_use_link
  get 'single_use_link/download/:id' => 'single_use_links_viewer#download', :as => :download_single_use_link

  match 'batch_edits/clear' => 'batch_edits#clear', :as => :batch_edits_clear, via: [:get, :post]

  # "Notifications" route for catalog index view
  get "users/notifications_number" => "users#notifications_number", :as => :user_notify

  # Generic file routes
  resources :generic_files, path: :files, except: :index do
    member do
      resource :featured_work, only: [:create, :destroy]
      get 'citation'
      get 'stats'
      post 'audit'
    end
  end

  resources :featured_work_lists, path: 'featured_works', only: :create

  # Downloads controller route
  resources :downloads, :only => "show"

  # Messages
  resources :notifications, only: [:destroy, :index], controller: :mailbox do
    collection do
      delete 'delete_all'
    end
  end

  # User profile & follows
  resources :users, only: [:index, :show, :edit, :update], as: :profiles do
    member do
      post 'trophy' => 'users#toggle_trophy' #used by trophy.js
      post 'follow' => 'users#follow'
      post 'unfollow' => 'users#unfollow'
    end
  end

  # Dashboard routes (based partly on catalog routes)
  resources 'dashboard', :only=>:index do
    collection do
      get 'page/:page', :action => :index
      get 'activity', :action => :activity, :as => :dashboard_activity
      get 'facet/:id', :action => :facet, :as => :dashboard_facet
    end
  end

  # advanced routes for advanced search
  get 'search' => 'advanced#index', :as => :advanced

  # Authority vocabulary queries route
  get 'authorities/:model/:term' => 'authorities#query'

  # LDAP-related routes for group and user lookups
  get 'directory/user/:uid' => 'directory#user'
  get 'directory/user/:uid/:attribute' => 'directory#user_attribute'
  get 'directory/group/:cn' => 'directory#group', :constraints => { :cn => /.*/ }

  # Batch edit routes
  get 'batches/:id/edit' => 'batch#edit', :as => :batch_edit
  post 'batches/:id/' => 'batch#update', :as => :batch_generic_files

  # Contact form routes
  post 'contact' => 'contact_form#create', :as => :contact_form_index
  get 'contact' => 'contact_form#new'

  # Resque monitoring routes. Don't bother with this route unless Sufia::ResqueAdmin
  # has been defined in the initalizers.
  if defined?(Sufia::ResqueAdmin)
    namespace :admin do
      constraints Sufia::ResqueAdmin do
        mount Resque::Server, :at => "queues"
      end
    end
  end

  resources :content_blocks, only: 'update'
  post '/tinymce_assets' => 'tinymce_assets#create'

  get 'about' => 'pages#show', id: 'about_page'
  # Static page routes (workaround)
  get ':action' => 'static#:action', :constraints => { :action => /help|terms|zotero|mendeley|agreement|subject_libraries|versions/ }, :as => :static

  #Single use link errors
  get 'single_use_link/not_found' => 'errors#single_use_error'
  get 'single_use_link/expired' => 'errors#single_use_error'

  # Catch-all (for routing errors)
  unless Rails.env.development? || Rails.env.test?
    match '*error' => 'errors#routing', via: [:get, :post]
  end

end
