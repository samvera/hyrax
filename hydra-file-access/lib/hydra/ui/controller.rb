# Basic view helpers & before_filters to support the default Hydra UI
# This mixin is *not required* in order for a Hydra Controller to function.  It is required if you want to use the default UI and javascript.
module Hydra::UI::Controller
  
  def self.included(base)
    base.helper :generic_content_objects
    base.helper :hydra_uploader
    base.helper :article_metadata
    base.before_filter :store_bounce
    base.before_filter :set_x_ua_compat
    base.before_filter :load_css
    base.before_filter :load_js
    base.before_filter :check_scripts
  end

  protected
  def store_bounce 
    session[:bounce]=params[:bounce]
  end
  
  def check_scripts
    session[:scripts] ||= (params[:combined] and params[:combined] == "true")
  end

  #
  # These are all setting view stuff in the style of Rails2 Blacklight.  
  # Current versions of Blacklight have pushed this stuff back out of the controllers and into views.
  #
  def set_x_ua_compat
    # Always force latest IE rendering engine & Chrome Frame through header information.
    response.headers["X-UA-Compatible"] = "IE=edge,chrome=1"
  end

  def load_css
  end

  def load_js
    # This JS file implementes Blacklight's JavaScript framework and simply assigns all of the Blacklight provided JS functionality to empty functions.
    # We can use this file in the future, however we will want to implement a jQuery plugin architecture as we actually add in JS functionality.
    javascript_includes << ["hydra/hydra-head"]
    javascript_includes << ['jquery.form.js']
    javascript_includes << ['spin.min.js' ]
  end

end
