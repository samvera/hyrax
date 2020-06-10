# frozen_string_literal: true
# Log a concern deposit to activity streams
class ContentDepositEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor} has deposited #{link_to repo_object.title.first, polymorphic_path(repo_object)}"
  end
end
