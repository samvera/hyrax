# A specific job to log a file content update to a user's activity stream
class ContentUpdateEventJob < ContentEventJob
  def action
    "User #{link_to_profile depositor_id} has updated #{link_to file_set.title.first, Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set)}"
  end
end
