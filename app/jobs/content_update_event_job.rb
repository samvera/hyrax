# Log content update to activity streams
class ContentUpdateEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor} has updated #{polymorphic_link_to(repo_object)}"
  end
end
