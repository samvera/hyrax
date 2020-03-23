# Log a fileset attachment to activity streams
class FileSetAttachedEventJob < ContentEventJob
  # Log the event to the fileset's and its container's streams
  def log_event(repo_object)
    repo_object.log_event(event)
    curation_concern.log_event(event)
  end

  def action
    "User #{link_to_profile depositor} has attached #{polymorphic_link_to(repo_object)} to #{polymorphic_link_to(curation_concern)}"
  end

  private

    def curation_concern
      repo_object.in_works.first
    end
end
