module Sufia::Controller
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior

    before_filter :notifications_number
  end

  def current_ability
    user_signed_in? ? current_user.ability : super
  end

  def render_404(exception)
    logger.error("Rendering 404 page due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render template: '/error/404', layout: "error", formats: [:html], status: 404
  end

  def render_500(exception)
    logger.error("Rendering 500 page due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render template: '/error/500', layout: "error", formats: [:html], status: 500
  end

  def render_single_use_error(exception)
    logger.error("Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render template: '/error/single_use_error', layout: "error", formats: [:html], status: 404
  end

  def notifications_number
    @notify_number = 0
    @batches = []
    return if action_name == "index" && controller_name == "mailbox"
    if user_signed_in?
      @notify_number = current_user.mailbox.inbox(unread: true).count
      @batches = current_user.mailbox.inbox.map { |msg| msg.last_message.body[/<span id="(.*)"><a (href=|data-content=|rel=)(.*)/,1] }.select{ |val| !val.blank? }
    end
  end

  # Override Devise method to redirect to dashboard after signing in
  def after_sign_in_path_for(resource)
    sufia.dashboard_index_path
  end

  protected

  ### Hook which is overridden in Sufia::Ldap::Controller
  def has_access?
    true
  end
end
