module Sufia::Controller
  extend ActiveSupport::Concern

  included do
    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = Sufia::SelectTypeListPresenter
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior
    helper_method :create_work_presenter
  end

  def current_ability
    user_signed_in? ? current_user.ability : super
  end

  # Override Devise method to redirect to dashboard after signing in
  def after_sign_in_path_for(_resource)
    sufia.dashboard_index_path
  end

  # A presenter for selecting a work type to create
  def create_work_presenter
    @create_work_presenter ||= create_work_presenter_class.new(current_user)
  end
end
