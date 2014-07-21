class BatchUpdateJob
  include Hydra::PermissionsQuery
  include Rails.application.routes.url_helpers

  def queue_name
    :batch_update
  end

  attr_accessor :login, :title, :file_attributes, :batch_id, :visibility

  def initialize(login, params)
    self.login = login
    self.title = params[:title]
    self.file_attributes = params[:generic_file]
    self.visibility = params[:visibility]
    self.batch_id = params[:id]
  end

  def run
    batch = Batch.find_or_create(self.batch_id)
    user = User.find_by_user_key(self.login)
    @saved = []
    @denied = []

    batch.generic_files.each do |gf|
      update_file(gf, user)
    end
    batch.update_attributes({status:["Complete"]})

    job_user = User.batchuser()

    message = '<span class="batchid ui-helper-hidden">ss-'+batch.noid+'</span>The file(s) '+ file_list(@saved)+ " have been saved." unless @saved.empty?
    job_user.send_message(user, message, 'Batch upload complete') unless @saved.empty?

    message = '<span class="batchid ui-helper-hidden">'+batch.noid+'</span>The file(s) '+ file_list(@denied)+" could not be updated.  You do not have sufficient privileges to edit it." unless @denied.empty?
    job_user.send_message(user, message, 'Batch upload permission denied') unless @denied.empty?
  end

  def update_file(gf, user)
    unless user.can? :edit, gf
      ActiveFedora::Base.logger.error "User #{user.user_key} DENIED access to #{gf.pid}!"
      @denied << gf
      return
    end
    gf.title = title[gf.pid] if title[gf.pid] rescue gf.label
    gf.attributes=file_attributes
    gf.visibility= visibility

    save_tries = 0
    begin
      gf.save!
    rescue RSolr::Error::Http => error
      save_tries += 1
      ActiveFedora::Base.logger.warn "BatchUpdateJob caught RSOLR error on #{gf.pid}: #{error.inspect}"
      # fail for good if the tries is greater than 3
      raise error if save_tries >=3
      sleep 0.01
      retry
    end #
    Sufia.queue.push(ContentUpdateEventJob.new(gf.pid, login))
    @saved << gf
  end

  def file_list ( files)
    files.map { |gf| '<a href="'+Sufia::Engine.routes.url_helpers.generic_files_path+'/'+gf.noid+'">'+gf.to_s+'</a>' }.join(', ')
  end
end
