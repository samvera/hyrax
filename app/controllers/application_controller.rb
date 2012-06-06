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

  ## Force the session to be restarted on every request.  The ensures that when the REMOTE_USER header is not set, the user will be logged out.
  before_filter :clear_session_user
  before_filter :set_current_user

  def clear_session_user
    # only logout if the REMOTE_USER is not set in the HTTP headers and a user is set within warden
    # logout clears the entire session including flash messages
    request.env['warden'].logout  unless ( (not env['warden'].user) || (request.env['HTTP_REMOTE_USER'])) if (env['warden'])
  end

  def set_current_user
      User.current = current_user
  end

  def render (object = nil)
     add_notifications
     super(object)
  end 


  def add_notifications
      # no where to put these notifications when doing create in generic files or java script requests
      return if ((action_name == "create") && (controller_name == "generic_files")) || (request.format== :js)

      if (User.current)
         inbox = User.current.mailbox.inbox
         notice = ''
         inbox.each() do |msg|
            logger.info "Message = #{msg.messages.inspect}"
            notice = notice+"<br>"+msg.last_message.body if (msg.last_message.subject == AuditJob::FAIL)
            msg.delete()
         end
         flash[:notice] = flash[:notice] ? flash[:notice]+notice : notice unless notice.blank?
      end
  end
  
  protect_from_forgery
end

