Sufia::Engine.routes.draw do
  match 'single_use_link/generate_download/:id' => 'single_use_link#generate_download', :as => :generate_download_single_use_link
  match 'single_use_link/generate_show/:id' => 'single_use_link#generate_show', :as => :generate_show_single_use_link
  match 'single_use_link/show/:id' => 'single_use_link#show', :as => :show_single_use_link
  match 'single_use_link/download/:id' => 'single_use_link#download', :as => :download_single_use_link

  match 'batch_edits/clear' => 'batch_edits#clear', :as => :batch_edits_clear

  # Route path-less requests to the index view of catalog
  root :to => "catalog#index"
  
  # "Recently added files" route for catalog index view
  match "catalog/recent" => "catalog#recent", :as => :catalog_recent

  # "Notifications" route for catalog index view
  match "users/notifications_number" => "users#notifications_number", :as => :user_notify

  # Generic file routes
  resources :generic_files, :path => :files, :except => :index do
    member do
      get 'citation', :as => :citation
      post 'audit'
    end
  end

  # Downloads controller route
  resources :downloads, :only => "show"

  # Login/logout route to destroy session
  # can just be in the PSU scholarsphere
  match 'logout' => 'sessions#destroy', :as => :destroy_user_session
  match 'login' => 'sessions#new', :as => :new_user_session

  # Messages
  match 'notifications' => 'mailbox#index', :as => :mailbox
  match 'notifications/delete_all' => 'mailbox#delete_all', :as => :mailbox_delete_all
  match 'notifications/:uid/delete' => 'mailbox#delete', :as => :mailbox_delete

  # User profile & follows
  match 'users' => 'users#index', :as => :profiles
  match 'users/:uid' => 'users#show', :as => :profile
  match 'users/:uid/edit' => 'users#edit', :as => :edit_profile
  match 'users/:uid/update' => 'users#update', :as => :update_profile, :via => :put
  match "users/:uid/trophy" => "users#toggle_trophy", :as => :update_trophy_user, :via => :post



  match 'users/:uid/follow' => 'users#follow', :as => :follow_user
  match 'users/:uid/unfollow' => 'users#unfollow', :as => :unfollow_user

  # Dashboard routes (based partly on catalog routes)
  resources 'dashboard', :only=>:index do
    collection do
      get 'page/:page', :action => :index
      get 'activity', :action => :activity, :as => :dashboard_activity
      get 'facet/:id', :action => :facet, :as => :dashboard_facet
    end
  end
    

  # advanced routes for advanced search
  match 'search' => 'advanced#index', :as => :advanced

  # Authority vocabulary queries route
  match 'authorities/:model/:term' => 'authorities#query'

  # LDAP-related routes for group and user lookups
  match 'directory/user/:uid' => 'directory#user'
  match 'directory/user/:uid/:attribute' => 'directory#user_attribute'
  match 'directory/group/:cn' => 'directory#group', :constraints => { :cn => /.*/ }

  # Batch edit routes
  match 'batches/:id/edit' => 'batch#edit', :as => :batch_edit
  match 'batches/:id/' => 'batch#update', :as => :batch_generic_files

  # Contact form routes
  match 'contact' => 'contact_form#create', :via => :post, :as => :contact_form_index
  match 'contact' => 'contact_form#new', :via => :get, :as => :contact_form_index

  # Resque monitoring routes
  namespace :admin do
    constraints Sufia::ResqueAdmin do
      mount Resque::Server, :at => "queues"
    end
  end

  # Static page routes (workaround)
  match ':action' => 'static#:action', :constraints => { :action => /about|help|terms|zotero|mendeley|agreement|subject_libraries|versions/ }, :as => :static
  
end

