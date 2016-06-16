module Sufia::Controller
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior
  end

  def current_ability
    user_signed_in? ? current_user.ability : super
  end

  # Override Devise method to redirect to dashboard after signing in
  def after_sign_in_path_for(_resource)
    sufia.dashboard_index_path
  end
end
