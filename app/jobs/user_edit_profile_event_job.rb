# A specific job to log a user profile edit to a user's activity stream
class UserEditProfileEventJob < EventJob
  alias_attribute :editor_id, :depositor_id

  def action
    "User #{link_to_profile editor_id} has edited his or her profile"
  end
end
