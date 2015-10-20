# A specific job to log a user following another user to a user's activity stream
class UserFollowEventJob < EventJob
  attr_accessor :followee_id
  alias_attribute :follower_id, :depositor_id

  def perform(follower_id, followee_id)
    @followee_id = followee_id
    super(follower_id)
  end

  # log the event to the users event stream
  def log_user_event
    super
    # Fan out the event to followee
    followee = User.find_by_user_key(followee_id)
    followee.log_event(event)
  end

  def action
    "User #{link_to_profile follower_id} is now following #{link_to_profile followee_id}"
  end
end
