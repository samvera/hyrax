class BatchUpdateJob < MetaSaveJob
  def initialize(login, params)
    params.symbolize_keys!
    batch = Batch.find_or_create(params[:id])
    user = User.find_by_login(login)

    saved = []
    denied = []
    batch.generic_files.each do |gf|
      unless user.can? :edit, get_permissions_solr_response_for_doc_id(gf.pid)[1]
        logger.error "DEEEENIED!"
        denied << gf
        next
      end 
      gf.title = params[:title][gf.pid] if params[:title][gf.pid] rescue gf.label 
      gf.update_attributes(params[:generic_file])
      gf.set_visibility(params)
      gf.save

      save_tries = 0 
      begin
        gf.save
      rescue RSolr::Error::Http => error
        logger.warn "GenericFilesController::create_and_save_generic_file Caught RSOLR error #{error.inspect}"
        save_tries++
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
      saved << gf
    end 
  end

end
