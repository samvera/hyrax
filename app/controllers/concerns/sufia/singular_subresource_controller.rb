module Sufia::SingularSubresourceController
  extend ActiveSupport::Concern

  included do
    load_and_authorize_resource ::FileSet, only: :file, id_param: :id
    load_and_authorize_resource ::GenericWork, only: :work, id_param: :id
  end

  # Overriding the default behavior from Hydra::Core::ControllerBehavior
  def deny_access(exception)
    if current_user && current_user.persisted?
      redirect_to root_path, alert: exception.message
    else
      session['user_return_to'.freeze] = request.url
      redirect_to new_user_session_path, alert: exception.message
    end
  end
end
