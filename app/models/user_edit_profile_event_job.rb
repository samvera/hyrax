class UserEditProfileEventJob < EventJob
  def initialize(editor_id)
    action = "User #{link_to editor_id, profile_path(editor_id)} has edited his or her profile"
    timestamp = Time.now.to_i
    editor = User.find_by_login(editor_id)
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
