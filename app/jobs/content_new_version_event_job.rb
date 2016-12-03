# Log new version of a file to activity streams
class ContentNewVersionEventJob < ContentEventJob
  def action
    @action ||= "User #{link_to_profile depositor} has added a new version of #{link_to repo_object.title.first, Rails.application.routes.url_helpers.hyrax_file_set_path(repo_object)}"
  end
end
