class UserUnfollowEventJob < EventJob
  def initialize(unfollower_id, unfollowee_id)
    message = "User #{link_to unfollower_id, profile_path(unfollower_id)} has unfollowed #{link_to unfollowee_id, profile_path(unfollowee_id)}"
    timestamp = Time.now.to_i
    unfollower = User.find_by_login(unfollower_id)
    # Log the event to the unfollower's stream
    unfollower.stream[:event].zadd(timestamp, message)
    # Fan out the event to unfollowee
    unfollowee = User.find_by_login(unfollowee_id)
    unfollowee.stream[:event].zadd(timestamp, message)
    # Fan out the event to all followers
    unfollower.followers.each do |user|
      user.stream[:event].zadd(timestamp, message)
    end
  end
end
