# Log new version of a file to activity streams
class ContentNewVersionEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor} has added a new version of #{polymorphic_link_to(repo_object)}"
  end
end
