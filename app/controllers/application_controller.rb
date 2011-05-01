#
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#

# Load Blacklight's ApplicationController first
require_plugin_dependency "vendor/plugins/blacklight/app/controllers/application_controller.rb"

class ApplicationController
  
  include HydraAccessControlsHelper
  
  helper :all
  helper :hydra_access_controls, :hydra_djatoka, :downloads, :hydra, :hydra_fedora_metadata, :hydra_assets, :hydra_uploader
  helper :generic_content_objects, :personalization #, :hydrangea_datasets
  
  # helper_method [:request_is_for_user_resource?]#, :user_logged_in?]
  before_filter [:store_bounce]
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '200c1e5f25e610288439b479ef176bbd'
  
  # This really shouldn't be an override.  What we SHOULD be doing is invoking another method in a before filter that will modify the javascript_includes and stylesheet_links arrays.
  # I don't know if there was a particular reason to do it like this so I'm not going to muck w/ it.  The way it is now, if BL adds something, or a file name changes (e.g. jQuery version) this will break.
  def default_html_head
    # when working offline, comment out the above uncomment the next line:
    #javascript_includes << ['jquery-1.4.2.min.js', 'jquery-ui-1.8.1.custom.min.js', { :plugin=>:blacklight } ]
    javascript_includes << ['http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js', 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.1/jquery-ui.min.js']
    javascript_includes << ['application', {:plugin=>"hydra-head"}]
    
    javascript_includes << ['blacklight', 'application', { :plugin=>:blacklight } ]
    
    stylesheet_links << ['yui', 'jquery/ui-lightness/jquery-ui-1.8.1.custom.css', 'application', {:plugin=>:blacklight, :media=>'all'}]
    stylesheet_links << ['redmond/jquery-ui-1.8.5.custom.css', {:plugin=>"hydra-head", :media=>'all'}]      
    stylesheet_links << ['styles', 'hydrangea', "hydrangea-split-button.css", {:plugin=>"hydra-head", :media=>'all'}]
    stylesheet_links << ['hydra/styles.css', {:plugin=>"hydra-head", :media=>'all'}]
  end
      
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
    @current_user.extend(Hydra::SuperuserAttributes)
  end
      
  protected
  def store_bounce 
    session[:bounce]=params[:bounce]
  end

end
