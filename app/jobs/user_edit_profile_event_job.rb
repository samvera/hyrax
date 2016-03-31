# A specific job to log a user profile edit to a user's activity stream
class UserEditProfileEventJob < EventJob
  def perform(editor)
    @editor = editor
    super
  end

  def action
    "User #{link_to_profile @editor} has edited his or her profile"
  end
end
