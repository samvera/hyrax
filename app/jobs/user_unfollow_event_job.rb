# A specific job to log a user unfollowing another user to a user's activity stream
class UserUnfollowEventJob < EventJob
  attr_accessor :unfollowee_id
  alias_attribute :unfollower_id, :depositor_id

  def perform(unfollower_id, unfollowee_id)
    @unfollowee_id = unfollowee_id
    super(unfollower_id)
  end

  # log the event to the users event stream
  def log_user_event
    super
    unfollowee = User.find_by_user_key(unfollowee_id)
    unfollowee.log_event(event)
  end

  def action
    "User #{link_to_profile unfollower_id} has unfollowed #{link_to_profile unfollowee_id}"
  end
end
