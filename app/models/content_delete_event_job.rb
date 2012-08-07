class ContentDeleteEventJob < EventJob
  def initialize(generic_file_id, depositor_id)
    message = "User #{link_to depositor_id, profile_path(depositor_id)} has deleted file '#{generic_file_id}'"
    timestamp = Time.now.to_i
    depositor = User.find_by_login(depositor_id)
    # Log the event to the depositor's profile stream
    depositor.stream[:event][:profile].zadd(timestamp, message)
    # Fan out the event to all followers
    depositor.followers.each do |follower|
      follower.stream[:event].zadd(timestamp, message)
    end
  end
end
