class UserFollowEventJob < EventJob
  def initialize(follower_id, followee_id)
    message = "User #{link_to follower_id, profile_path(follower_id)} is now following #{link_to followee_id, profile_path(followee_id)}"
    timestamp = Time.now.to_i
    follower = User.find_by_login(follower_id)
    # Log the event to the follower's stream
    follower.stream[:event].zadd(timestamp, message)
    # Fan out the event to followee
    followee = User.find_by_login(followee_id)
    followee.stream[:event].zadd(timestamp, message)
    # Fan out the event to all followers
    follower.followers.each do |user|
      user.stream[:event].zadd(timestamp, message)
    end
  end
end
