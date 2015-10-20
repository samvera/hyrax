# A specific job to log a file restored version to a user's activity stream
class ContentRestoredVersionEventJob < ContentEventJob
  attr_accessor :revision_id

  def perform(generic_file_id, depositor_id, revision_id)
    @revision_id = revision_id
    super(generic_file_id, depositor_id)
  end

  def action
    "User #{link_to_profile depositor_id} has restored a version '#{revision_id}' of #{link_to file_set.title.first, Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set)}"
  end
end
