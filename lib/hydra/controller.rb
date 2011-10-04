# Adds behaviors that Hydra needs all controllers to have. (mostly view helpers)
module Hydra::Controller
  def self.included(base)
    base.helper :hydra_assets
    base.helper :hydra_fedora_metadata
    base.helper :generic_content_objects
    base.before_filter :store_bounce
    base.before_filter :set_x_ua_compat
    base.before_filter :load_css
    base.before_filter :load_js
  end
  
  protected
  def store_bounce 
    session[:bounce]=params[:bounce]
  end

  def set_x_ua_compat
    # Always force latest IE rendering engine & Chrome Frame through header information.
    response.headers["X-UA-Compatible"] = "IE=edge,chrome=1"
  end
  
  def load_css
    stylesheet_links << ["hydra/html_refactor", {:media=>"all"}]
  end

  def load_js
    # This JS file implementes Blacklight's JavaScript framework and simply assigns all of the Blacklight provided JS functionality to empty functions.
    # We can use this file in the future, however we will want to implement a jQuery plugin architecture as we actually add in JS functionality.
    javascript_includes << ["hydra/hydra-head"]
    javascript_includes << ['jquery.form.js']
    javascript_includes << ['spin.min.js' ]
  end
end