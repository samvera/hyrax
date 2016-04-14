# A generic job for sending events about repository objects to a user and their followers.
#
# @attr [String] repo_object the object event is specified for
#
class ContentEventJob < EventJob
  attr_reader :repo_object
  def perform(repo_object, depositor)
    @repo_object = repo_object
    super(depositor)
    log_event(repo_object)
  end

  # Log the event to the object's stream
  def log_event(repo_object)
    repo_object.log_event(event)
  end

  # override to check file permissions before logging to followers
  def log_to_followers(depositor)
    depositor.followers.select { |user| user.can?(:read, repo_object) }.each do |follower|
      follower.log_event(event)
    end
  end

  # log the event to the users profile stream
  def log_user_event(depositor)
    depositor.log_profile_event(event)
  end
end
