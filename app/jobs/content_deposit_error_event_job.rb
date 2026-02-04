# frozen_string_literal: true
# Log a concern deposit to activity streams
class ContentDepositErrorEventJob < ContentEventJob
  attr_accessor :reason

  def perform(repo_object, depositor, reason: '')
    self.reason = reason
    super(repo_object, depositor)
  end

  def action
    "User #{link_to_profile depositor} deposit of #{link_to repo_object.title.first, polymorphic_path(repo_object)} has failed for #{reason}"
  end
end
