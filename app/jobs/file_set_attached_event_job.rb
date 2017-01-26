# Log a fileset attachment to activity streams
class FileSetAttachedEventJob < ContentEventJob
  # Log the event to the fileset's and its container's streams
  def log_event(repo_object)
    repo_object.log_event(event)
    curation_concern.log_event(event)
  end

  def action
    "User #{link_to_profile depositor} has attached #{file_link} to #{work_link}"
  end

  private

    def file_link
      link_to file_title, polymorphic_path(repo_object)
    end

    def work_link
      link_to work_title, polymorphic_path(curation_concern)
    end

    def file_title
      repo_object.title.first
    end

    def work_title
      curation_concern.title.first
    end

    def curation_concern
      repo_object.in_works.first
    end
end
