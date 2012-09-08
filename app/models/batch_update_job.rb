class BatchUpdateJob < EventJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include ApplicationHelper

  def self.queue
    :batch_update
  end

  #def self.perform(batch_id, gen_file, login, params)
  def self.perform(login, params)
    params.symbolize_keys!
    batch = Batch.find_or_create(params[:id])
    logger.error "---------------------"
    logger.error "params: #{params.inspect}"
    logger.error "---------------------"

    saved = []
    denied = []
    batch.generic_files.each do |gf|
      unless can? :read, get_permissions_solr_response_for_doc_id(gf.pid)
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
