class BatchUpdateJob < MetaSaveJob
  def initialize(login, params)
    params.symbolize_keys!
    batch = Batch.find_or_create(params[:id])
    user = User.find_by_login(login)
    logger.error "---------------------"
    logger.error "params: #{params.inspect}"
    logger.error "---------------------"
    logger.error "user: #{user.inspect}"

    saved = []
    denied = []
    batch.generic_files.each do |gf|
      logger.error "---------------------"
      logger.error "pid: #{gf.pid}"
      logger.error "---------------------"
      if user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)
        logger.error "if is true???"
      else
        logger.error "not true???"
      end

      unless user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)
        logger.error "DEEEENIED!"
        denied << gf
        next
      end 
      logger.error "going through--"
      logger.error "p title#{params[:title]}"
      logger.error "p gfile#{params[:generic_file]}"
      gf.title = params[:title][gf.pid] if params[:title][gf.pid] rescue gf.label 
      gf.update_attributes(params[:generic_file])
      gf.set_visibility(params)
      gf.save
      begin
        Resque.enqueue(ContentUpdateEventJob, gf.pid, login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end 
      saved << gf
    end 
  end

end
