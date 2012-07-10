class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  before_filter do |controller|
    # TODO: move this to app/assets/stylesheets and turn on the asset pipeline
    controller.stylesheet_links << 'bootstrap.min.css'
  end

  ## Force the session to be restarted on every request.  The ensures that when the REMOTE_USER header is not set, the user will be logged out.
  before_filter :clear_session_user
  before_filter :set_current_user

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
    # only logout if the REMOTE_USER is not set in the HTTP headers and a user is set within warden
    # logout clears the entire session including flash messages
    if request.nil?
      logger.warn "Request is Nil, how weird!!!"
      return
    end
    request.env['warden'].logout if env['warden'] and env['warden'].user and request.env['REMOTE_USER']
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

  def render (object=nil)
    add_notifications
    super(object)
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
end
