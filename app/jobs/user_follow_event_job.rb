class UserFollowEventJob < EventJob
  attr_accessor :follower_id, :followee_id

  def initialize(follower_id, followee_id)
    self.follower_id = follower_id
    self.followee_id = followee_id
  end

  def run
    # Create the event
    follower = User.find_by_user_key(follower_id)
    event = follower.create_event("User #{link_to_profile follower_id} is now following #{link_to_profile followee_id}", Time.now.to_i)
    # Log the event to the follower's stream
    follower.log_event(event)
    # Fan out the event to followee
    followee = User.find_by_user_key(followee_id)
    followee.log_event(event)
    # Fan out the event to all followers
    follower.followers.each do |user|
      user.log_event(event)
    end
  end
end
