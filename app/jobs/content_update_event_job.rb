class ContentUpdateEventJob < EventJob
  def perform(id, depositor_id)
    fs = FileSet.find(id)
    action = "User #{link_to_profile depositor_id} has updated #{link_to fs.title.first, Rails.application.routes.url_helpers.curation_concerns_file_set_path(fs)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_user_key(depositor_id)
    # Create the event
    event = depositor.create_event(action, timestamp)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Log the event to the FS's stream
    fs.log_event(event)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, fs }.each do |follower|
      follower.log_event(event)
    end
  end
end
