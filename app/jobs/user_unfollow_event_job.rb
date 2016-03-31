# A specific job to log a user unfollowing another user to a user's activity stream
class UserUnfollowEventJob < EventJob
  attr_accessor :unfollowee, :unfollower

  def perform(unfollower, unfollowee)
    @unfollower = unfollower
    @unfollowee = unfollowee
    super(unfollower)
  end

  # log the event to the users event stream
  def log_user_event(_unfollower)
    super
    unfollowee.log_event(event)
  end

  def action
    "User #{link_to_profile unfollower} has unfollowed #{link_to_profile unfollowee}"
  end
end
