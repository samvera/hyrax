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
      begin
        Resque.enqueue(ContentUpdateEventJob, gf.pid, login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end 
      saved << gf
    end 
  end

end
