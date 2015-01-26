class ContentDeleteEventJob < EventJob

  def run
    action = "User #{link_to_profile depositor_id} has deleted file '#{generic_file_id}'"
    timestamp = Time.now.to_i
    depositor = User.find_by_user_key(depositor_id)
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
