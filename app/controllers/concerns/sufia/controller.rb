module Sufia::Controller
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior

    before_action :notifications_number
  end

  def current_ability
    user_signed_in? ? current_user.ability : super
  end

  def render_500(exception)
    logger.error("Rendering 500 page due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render template: '/error/500', layout: "error", formats: [:html], status: 500
  end

  def notifications_number
    @notify_number = 0
    @upload_sets = []
    return if action_name == "index" && controller_name == "mailbox"
    return unless user_signed_in?
    @notify_number = current_user.mailbox.inbox(unread: true).count
    # Extract the ids of the upload sets that have completed batch processing
    @upload_sets = current_user.mailbox.inbox.map { |msg| msg.last_message.body[/<span id="(.*)"><a (href=|data-content=|data-toggle=)(.*)/, 1] }.select { |val| !val.blank? }
  end

  # Override Devise method to redirect to dashboard after signing in
  def after_sign_in_path_for(_resource)
    sufia.dashboard_index_path
  end

  protected

    ### Hook which is overridden in Sufia::Ldap::Controller
    def has_access?
      true
    end
end
