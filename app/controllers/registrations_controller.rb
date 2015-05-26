class RegistrationsController < Devise::RegistrationsController
  include CurationConcerns::ThemedLayoutController
  with_themed_layout '1_column'

  protected

  # def after_update_path_for(resource)
  #   resource.update_column(:user_does_not_require_profile_update, true)
  #   super
  # end

  # def resource_class
  #   Account
  # end

  # def sign_up(resource_name, resource)
  #   sign_in(resource_name, resource.user)
  # end

end
