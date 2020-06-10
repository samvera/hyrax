# frozen_string_literal: true
# Log content update to activity streams
class ContentUpdateEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor} has updated #{link_to repo_object.title.first, polymorphic_path(repo_object)}"
  end
end
