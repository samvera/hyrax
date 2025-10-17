# frozen_string_literal: true
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
    concern = case repo_object
              when ActiveFedora::Base
                repo_object.in_works.first
              else
                Hyrax.query_service.find_parents(resource: repo_object).first
              end
    raise StandardError("Could not find parent - FileSet w/ id #{repo_object.id} not successfully attached to parent") unless concern
    concern
  end
end
