class UserEditProfileEventJob < EventJob
  def initialize(editor_id)
    message = "User #{link_to editor_id, profile_path(editor_id)} has edited his or her profile"
    timestamp = Time.now.to_i
    editor = User.find_by_login(editor_id)
    # Log the event to the editor's stream
    editor.stream[:event].zadd(timestamp, message)
    # Fan out the event to all followers
    editor.followers.each do |user|
      user.stream[:event].zadd(timestamp, message)
    end
  end
end
