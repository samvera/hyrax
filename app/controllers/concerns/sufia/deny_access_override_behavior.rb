module Sufia
  module DenyAccessOverrideBehavior
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
end
