# Log user profile edits to activity streams
class UserEditProfileEventJob < EventJob
  def perform(editor)
    @editor = editor
    super
  end

  def action
    "User #{link_to_profile @editor} has edited his or her profile"
  end
end
