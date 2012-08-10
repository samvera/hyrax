class UserFollowEventJob < EventJob
  def initialize(follower_id, followee_id)
    action = "User #{link_to follower_id, profile_path(follower_id)} is now following #{link_to followee_id, profile_path(followee_id)}"
    timestamp = Time.now.to_i
    follower = User.find_by_login(follower_id)
    # Create the event
    event = follower.create_event(action, timestamp)
    # Log the event to the follower's stream
    follower.log_event(event)
    # Fan out the event to followee
    followee = User.find_by_login(followee_id)
    followee.log_event(event)
    # Fan out the event to all followers
    follower.followers.each do |user|
      user.log_event(event)
    end
  end
end
