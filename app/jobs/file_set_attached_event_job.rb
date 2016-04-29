# Log a fileset attachment to activity streams
class FileSetAttachedEventJob < ContentEventJob
  # Log the event to the fileset's and its container's streams
  def log_event(repo_object)
    repo_object.log_event(event)
    curation_concern.log_event(event)
  end

  def action
    "User #{link_to_profile depositor} has attached #{link_to repo_object.title.first, polymorphic_path(repo_object)} to #{link_to curation_concern.title.first, polymorphic_path(curation_concern)}"
  end

  private

    def curation_concern
      repo_object.in_works.first
    end
end
