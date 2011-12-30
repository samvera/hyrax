class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller

  def layout_name
   'hydra-head'
  end

  ApplicationController.before_filter do |controller|
    # remove default jquery-ui theme.
    # controller.stylesheet_links.each do |args|
    #   args.delete_if {|a| a =~
    #   /^|\/jquery-ui-[\d.]+\.custom\.css$/ }
    # end
 
    # add in a different jquery-ui theme, or any other css or what
    #     have you
    controller.stylesheet_links << 'bootstrap.min.css'

    #     controller.javascript_includes << "my_local_behaviors.js"

    #     controller.extra_head_content << '<link rel="something"
    #     href="something">'
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery
end
