# Log a concern deposit to activity streams
class ContentDepositEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor} has deposited #{polymorphic_link_to(repo_object)}"
  end
end
