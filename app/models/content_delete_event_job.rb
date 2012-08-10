class ContentDeleteEventJob < EventJob
  def initialize(generic_file_id, depositor_id)
    action = "User #{link_to depositor_id, profile_path(depositor_id)} has deleted file '#{generic_file_id}'"
    timestamp = Time.now.to_i
    depositor = User.find_by_login(depositor_id)
    # Create the event
    event = depositor.create_event(action, timestamp)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Fan out the event to all followers
    depositor.followers.each do |follower|
      follower.log_event(event)
    end
  end
end
