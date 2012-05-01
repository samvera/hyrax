class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller

  def layout_name
   'hydra-head'
  end

  before_filter do |controller|
    # TODO move this to app/assets/stylesheets and turn on the asset pipeline
    controller.stylesheet_links << 'bootstrap.min.css'
  end

  protect_from_forgery
end

