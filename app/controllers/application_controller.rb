class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller

  def layout_name
   'hydra-head'
  end

  before_filter do |controller|
    controller.stylesheet_links << 'bootstrap.min.css'
  end

  protect_from_forgery
end

