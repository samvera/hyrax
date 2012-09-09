class BatchUpdateJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include ApplicationHelper

  def self.queue
    :batch_update
  end

  def self.perform(*args)
    new(*args)
  end

  def initialize(login, params)
    params.symbolize_keys!
    batch = Batch.find_or_create(params[:id])
    user = User.find_by_login(login)

    # TODO: Determine if we need to use these two arrays. Commented out all lines for now.
    #saved = []
    #denied = []
    batch.generic_files.each do |gf|
      unless user.can? :edit, get_permissions_solr_response_for_doc_id(gf.pid)[1]
        logger.error "User #{user.login} DEEEENIED access to #{gf.pid}!"
        #denied << gf
        next
      end
      gf.title = params[:title][gf.pid] if params[:title][gf.pid] rescue gf.label
      gf.update_attributes(params[:generic_file])
      gf.set_visibility(params)

      save_tries = 0
      begin
        gf.save
      rescue RSolr::Error::Http => error
        save_tries += 1
        logger.warn "BatchUpdateJob caught RSOLR error on #{gf.pid}: #{error.inspect}"
        # fail for good if the tries is greater than 3
        rescue_action_without_handler(error) if save_tries >=3
        sleep 0.01
        retry
      end

      begin
        Resque.enqueue(ContentUpdateEventJob, gf.pid, login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end
      #saved << gf
    end
  end
end
