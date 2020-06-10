# frozen_string_literal: true
# Log user profile edits to activity streams
class UserEditProfileEventJob < EventJob
  def perform(editor)
    @editor = editor
    super
  end

  def action
    "User #{link_to_profile @editor} has edited their profile"
  end
end
