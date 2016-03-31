# A generic job for sending events about a generic files to a user and their followers.
#
# @attr [String] file_set_id  the id of the file the event is specified for
#
class ContentEventJob < EventJob
  attr_reader :file_set
  def perform(file_set, depositor)
    @file_set = file_set
    super(depositor)
    log_file_set_event(file_set)
  end

  # Log the event to the FileSet's stream
  def log_file_set_event(file_set)
    file_set.log_event(event) unless file_set.nil?
  end

  # override to check file permissions before logging to followers
  def log_to_followers(depositor)
    depositor.followers.select { |user| user.can?(:read, file_set) }.each do |follower|
      follower.log_event(event)
    end
  end

  # log the event to the users profile stream
  def log_user_event(depositor)
    depositor.log_profile_event(event)
  end
end
