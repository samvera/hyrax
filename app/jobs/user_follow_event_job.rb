# Log user following another user to activity streams
class UserFollowEventJob < EventJob
  attr_accessor :followee, :follower

  def perform(follower, followee)
    @follower = follower
    @followee = followee
    super(follower)
  end

  # log the event to the users event stream
  def log_user_event(user)
    super
    # Fan out the event to followee
    followee.log_event(event)
  end

  def action
    "User #{link_to_profile follower} is now following #{link_to_profile followee}"
  end
end
