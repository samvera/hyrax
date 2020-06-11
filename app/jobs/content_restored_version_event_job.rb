# frozen_string_literal: true
# Log file restored version to activity streams
class ContentRestoredVersionEventJob < ContentEventJob
  attr_accessor :revision_id

  def perform(file_set, depositor, revision_id)
    @revision_id = revision_id
    super(file_set, depositor)
  end

  def action
    "User #{link_to_profile depositor} has restored a version '#{revision_id}' of #{link_to repo_object.title.first, Rails.application.routes.url_helpers.hyrax_file_set_path(repo_object)}"
  end
end
