class UserEditProfileEventJob < EventJob
  attr_accessor :editor_id

  def initialize(editor_id)
    self.editor_id = editor_id
  end

  def run
    action = "User #{link_to_profile editor_id} has edited his or her profile"
    timestamp = Time.now.to_i
    editor = User.find_by_user_key(editor_id)
    # Create the event
    event = editor.create_event(action, timestamp)
    # Log the event to the editor's stream
    editor.log_event(event)
    # Fan out the event to all followers
    editor.followers.each do |user|
      user.log_event(event)
    end
  end
end
