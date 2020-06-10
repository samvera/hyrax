# frozen_string_literal: true
module Hyrax
  module DenyAccessOverrideBehavior
    # Overriding the default behavior from Hydra::Core::ControllerBehavior
    def deny_access(exception)
      if current_user&.persisted?
        redirect_to root_path, alert: exception.message
      else
        session['user_return_to'] = request.url
        redirect_to main_app.new_user_session_path, alert: exception.message
      end
    end
  end
end
