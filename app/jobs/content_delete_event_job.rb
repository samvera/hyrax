# frozen_string_literal: true
# Log object deletion to activity streams
#
# @attr_reader deleted_work_id The id of the work that has been deleted by the user
class ContentDeleteEventJob < EventJob
  attr_reader :deleted_work_id

  def perform(deleted_work_id, depositor)
    @deleted_work_id = deleted_work_id
    super(depositor)
  end

  def action
    @action ||= "User #{link_to_profile depositor} has deleted object '#{deleted_work_id}'"
  end

  # override to log the event to the users profile stream instead of the user's stream
  def log_user_event(depositor)
    depositor.log_profile_event(event)
  end
end
