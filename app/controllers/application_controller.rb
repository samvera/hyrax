class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  ## Force the session to be restarted on every request.  The ensures that when the REMOTE_USER header is not set, the user will be logged out.
  before_filter :clear_session_user
  before_filter :set_current_user
  before_filter :filter_notify
  before_filter :add_notifications

  # Intercept errors and render user-friendly pages
  rescue_from NameError, :with => :render_500
  rescue_from RuntimeError, :with => :render_500
  rescue_from ActionView::Template::Error, :with => :render_500
  rescue_from ActiveRecord::StatementInvalid, :with => :render_500
  rescue_from Mysql2::Error, :with => :render_500
  rescue_from Net::LDAP::LdapError, :with => :render_500
  rescue_from RSolr::Error::Http, :with => :render_500
  rescue_from Rubydora::FedoraInvalidRequest, :with => :render_500
  rescue_from ActionDispatch::Cookies::CookieOverflow, :with => :render_500
  rescue_from AbstractController::ActionNotFound, :with => :render_404
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  rescue_from ActionController::RoutingError, :with => :render_404
  rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :render_404

  def layout_name
    'hydra-head'
  end

  def clear_session_user
    if request.nil?
      logger.warn "Request is Nil, how weird!!!"
      return
    end

    # only logout if the REMOTE_USER is not set in the HTTP headers and a user is set within warden
    # logout clears the entire session including flash messages
    request.env['warden'].logout if user_logged_in?
  end

  def set_current_user
    User.current = current_user
  end

  def render_404(exception)
    logger.error("Rendering 404 page due to exception: #{exception.inspect} - #{exception.backtrace}")
    render :template => '/error/404', :layout => "error", :formats => [:html], :status => 404
  end

  def render_500(exception)
    logger.error("Rendering 500 page due to exception: #{exception.inspect} - #{exception.backtrace}")
    render :template => '/error/500', :layout => "error", :formats => [:html], :status => 500
  end

  def filter_notify
    # remove error inserted if the user does in fact login
    if user_logged_in? and flash[:alert].present?
      # first remove the bogus message
      flash[:alert].sub!('You need to sign in or sign up before continuing.', '')
      # then make the flash nil if that was the only message in the flash
      flash[:alert] = nil if flash[:alert].blank?
    end
  end

  def add_notifications
    # no where to put these notifications when doing create in generic files or java script requests
    return if ((action_name == "create") && (controller_name == "generic_files")) || (request.format== :js)

    if User.current
      inbox = User.current.mailbox.inbox
      notice = ''
      inbox.each do |msg|
        #logger.info "Message = #{msg.messages.inspect}"
        notice = notice+"<br>"+msg.last_message.body if (msg.last_message.subject == AuditJob::FAIL)

        # we are cleaning up the hard way here so that we do not get a raise condition with locks.
        # does not seem to happen on dev enviromnet but it is happening in integration
        msg.messages.each do |notify|
          notify.receipts.each do |receipt|
            receipt.delete
          end
          notify.delete
        end
        msg.delete
      end
      unless notice.blank?
        flash[:notice] ||= ''
        flash[:notice] << notice
      end
    end
  end

  protected
  # Returns the solr permissions document for the given id
  # @return solr permissions document
  # @example This is the document that you can pass into permissions enforcement methods like 'can?'
  #   gf = GenericFile.find(params[:id])
  #   if can? :read, permissions_solr_doc_for_id(gf.pid)
  #     gf.update_attributes(params[:generic_file])
  #   end
  def permissions_solr_doc_for_id(id)
    permissions_solr_response, permissions_solr_document = get_permissions_solr_response_for_doc_id(id)
    return permissions_solr_document
  end

  protect_from_forgery

  def user_logged_in?
    env['warden'] and env['warden'].user and remote_user_blank?
  end

  def remote_user_blank?
    # Unicorn seems to translate REMOTE_USER into HTTP_REMOTE_USER
    if Rails.env.development?
      request.env['HTTP_REMOTE_USER'].blank?
    else
      request.env['REMOTE_USER'].blank?
    end
  end
end
