class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include PSU::Noid
  include Dil::RightsMetadata
  
  include ActiveModel::Validations::HelperMethods 
    
  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
  has_file_datastream :name => "content", :type => FileContentDatastream
  has_file_datastream :name => "thumbnail", :type => FileContentDatastream

  belongs_to :batch, :property => :is_part_of

  delegate :related_url, :to => :descMetadata
  delegate :based_near, :to => :descMetadata
  delegate :part_of, :to => :descMetadata
  delegate :contributor, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :title, :to => :descMetadata
  delegate :tag, :to => :descMetadata
  delegate :description, :to => :descMetadata
  delegate :publisher, :to => :descMetadata
  delegate :date_created, :to => :descMetadata
  delegate :date_uploaded, :to => :descMetadata, :unique => true
  delegate :date_modified, :to => :descMetadata, :unique => true
  delegate :subject, :to => :descMetadata
  delegate :language, :to => :descMetadata
  delegate :date, :to => :descMetadata
  delegate :rights, :to => :descMetadata
  delegate :resource_type, :to => :descMetadata
  delegate :format, :to => :descMetadata
  delegate :identifier, :to => :descMetadata
  delegate :format_label, :to => :characterization
  delegate :mime_type, :to => :characterization, :unique => true
  delegate :file_size, :to => :characterization
  delegate :last_modified, :to => :characterization
  delegate :filename, :to => :characterization
  delegate :original_checksum, :to => :characterization
  delegate :rights_basis, :to => :characterization
  delegate :copyright_basis, :to => :characterization
  delegate :copyright_note, :to => :characterization
  delegate :well_formed, :to => :characterization
  delegate :valid, :to => :characterization
  delegate :status_message, :to => :characterization
  delegate :file_title, :to => :characterization
  delegate :file_author, :to => :characterization
  delegate :page_count, :to => :characterization
  delegate :file_language, :to => :characterization
  delegate :word_count, :to => :characterization
  delegate :character_count, :to => :characterization
  delegate :paragraph_count, :to => :characterization
  delegate :line_count, :to => :characterization
  delegate :table_count, :to => :characterization
  delegate :graphics_count, :to => :characterization
  delegate :byte_order, :to => :characterization
  delegate :compression, :to => :characterization
  delegate :width, :to => :characterization
  delegate :height, :to => :characterization
  delegate :color_space, :to => :characterization
  delegate :profile_name, :to => :characterization
  delegate :profile_version, :to => :characterization
  delegate :orientation, :to => :characterization
  delegate :color_map, :to => :characterization
  delegate :image_producer, :to => :characterization
  delegate :capture_device, :to => :characterization
  delegate :scanning_software, :to => :characterization
  delegate :exif_version, :to => :characterization
  delegate :gps_timestamp, :to => :characterization
  delegate :latitude, :to => :characterization
  delegate :longitude, :to => :characterization
  delegate :character_set, :to => :characterization
  delegate :markup_basis, :to => :characterization
  delegate :markup_language, :to => :characterization
  delegate :duration, :to => :characterization
  delegate :bit_depth, :to => :characterization
  delegate :sample_rate, :to => :characterization
  delegate :channels, :to => :characterization
  delegate :data_format, :to => :characterization
  delegate :offset, :to => :characterization

  around_save :characterize_if_changed

  NO_RUNS = 999

  #make sure the terms of service is present and set to 1 before saving
  # note GenericFile.create will no longer save a GenericFile as the terms_of_service will not be set 
  terms_of_service = nil
  validates_acceptance_of :terms_of_service, :allow_nil=>false

  # set the terms of service on create so an empty generic file can be created
  #before_validation(:on => :create) do
  #  logger.info "!!!! Before create !!!!"
  #  self.terms_of_service = '1'
  #end

  ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
  def permissions=(params)
    perm_hash = permission_hash
    perm_hash['person'][params[:new_user_name]] = params[:new_user_permission] if params[:new_user_name].present?
    perm_hash['group'][params[:new_group_name]] = params[:new_group_permission] if params[:new_group_name].present?

    params[:user].each { |name, access| perm_hash['person'][name] = access} if params[:user]
    params[:group].each { |name, access| perm_hash['group'][name] = access} if params[:group]
    rightsMetadata.update_permissions(perm_hash)
  end

  def characterize_if_changed
    content_changed = self.content.changed?
    yield
    logger.debug "DOING CHARACTERIZE ON #{self.pid}"
    Delayed::Job.enqueue(CharacterizeJob.new(self.pid), :queue => 'characterize') if content_changed
  end

  ## Extract the metadata from the content datastream and record it in the characterization datastream
  def characterize
    self.characterization.content = self.content.extract_metadata
    self.append_metadata
    self.filename = self.label
    self.terms_of_service = '1'    
    save unless self.new_object?
  end

  def related_files
    relateds = begin
                 self.batch.generic_files
               rescue NoMethodError
                 batch_id = self.object_relations["isPartOf"].first || self.object_relations[:is_part_of].first
                 return [] if batch_id.nil?
                 self.class.find(:is_part_of_s => batch_id)
               end
    relateds.reject { |gf| gf.pid == self.pid }
  end

  # Create thumbnail requires that the characterization has already been run (so mime_type, width and height is available)
  # and that the object is already has a pid set
  def create_thumbnail
    return if self.content.content.nil?
    if ["application/pdf"].include? self.mime_type
      create_pdf_thumbnail
    elsif ["image/png","image/jpeg", "image/gif"].include? self.mime_type
      create_image_thumbnail
    # if we can figure out how to do video
    #elsif ["video/mpeg", "video/mp4"].include? self.mime_type
    # TODO
    end
  end
  
  # redefine find so that it sets the terms of service
  def self.find(args, opts={}) 
    gf = super
    # use the field type to see if the retun will be one item or multiple
    if args.class == String
      gf.terms_of_service = '1'
    else 
      gf.each {|f| f.terms_of_service = '1'}
    end
    return gf 
  end

  def create_pdf_thumbnail
    pdf = Magick::ImageList.new
    pdf.from_blob(content.content)
    first = pdf.to_a[0]
    first.format = "PNG"   
    thumb = first.scale(45, 60)
    self.thumbnail.content = thumb.to_blob { self.format = "PNG" }
    logger.debug "Has the content changed before saving? #{self.content.changed?}"
    self.terms_of_service = '1'    
    self.save
  end

  def create_image_thumbnail
    img = Magick::ImageList.new
    img.from_blob(content.content)
    # horizontal img
    height = self.height.first.to_i
    width = self.width.first.to_i
    if width > height
      if width > 50 and height > 35 
        thumb = img.scale(50, 35)
      else
        thumb = img.scale(width, height)
      end
    # vertical img
    else
      if width > 45 and height > 60 
        thumb = img.scale(45, 60)
      else
        thumb = img.scale(width, height)
      end
    end
    self.thumbnail.content = thumb.to_blob
    self.terms_of_service = '1'    
    logger.debug "Has the content before saving? #{self.content.changed?}"
    self.save
  end

  def append_metadata
    terms = self.characterization_terms
    ScholarSphere::Application.config.fits_to_desc_mapping.each_pair do |k, v|
      if terms.has_key?(k)
        # coerce to array to remove a conditional
        terms[k] = [terms[k]] unless terms[k].is_a? Array
        terms[k].each do |term_value|
          proxy_term = self.send(v)
          if proxy_term.kind_of?(Array)
            proxy_term << term_value unless proxy_term.include?(term_value)
          else
            # these are single-valued terms which cannot be appended to
            self.send("#{v}=", term_value)
          end            
        end
      end
    end
  end
  
  def to_solr(solr_doc={})
    super(solr_doc)
    solr_doc["label_t"] = self.label
    solr_doc["noid_s"] = noid
    return solr_doc
  end
  
  def label=(new_label)
    @inner_object.label = new_label
    if self.title.empty?
      self.title = new_label
    end
  end

  def to_jq_upload
    return {
      "name" => self.title,
      "size" => self.file_size,
      "url" => "/files/#{noid}",
      "thumbnail_url" => self.pid,
      "delete_url" => "deleteme", # generic_file_path(:id => id),
      "delete_type" => "DELETE" 
    }
  end

  def get_terms
    terms = []
    self.descMetadata.class.config[:predicate_mapping].each do |uri, mappings|
      new_terms = mappings.keys.map(&:to_s).select do |term|
        term.start_with? "generic_file__" and !['solrtype', 'solrbehaviors'].include? term.split('__').last
      end
      terms.concat(new_terms)
    end 
    terms
  end

  def characterization_terms
    h = {}
    self.characterization.class.terminology.terms.each_pair do |k, v|
      next unless v.respond_to? :proxied_term
      term = v.proxied_term
      begin
        value = self.send(term.name)
        h[term.name] = value unless value.empty?
      rescue NoMethodError
        next
      end
    end
    h
  end

  def logs(dsid)
    ChecksumAuditLog.where(:dsid=>dsid, :pid=>self.pid).order('created_at desc, id desc')
  end

  def audit!
    audit(true)
  end
  
  def audit_stat!
    audit_stat(true)
  end
  
  def audit_stat(force = false)
    logs = audit(force)
    audit_results = logs.collect { |result| result["pass"] }
    
    # check how many non runs we had
    non_runs =audit_results.reduce(0) { |sum, value| (value == NO_RUNS) ? sum = sum+1 : sum }
    if (non_runs == 0)
      result =audit_results.reduce(true) { |sum, value| sum && value }
      return result
    elsif (non_runs < audit_results.length)
      result =audit_results.reduce(true) { |sum, value| (value == NO_RUNS) ? sum : sum && value }
      return 'Some audits have not been run, but the ones run where '+ ((result)? 'passing' : 'failing') + '.'
    else 
      return 'Audits have not yet been run on this file.'
    end
  end

  def audit(force = false)
    logs = []
    self.per_version do |ver| 
      logs << GenericFile.audit(ver, force)
    end
    logs
  end

  def per_version(&block)
    self.datastreams.each do |dsid, ds|
      ds.versions.each do |ver|
        block.call(ver)
      end
    end
  end

  def self.audit!(version)
    GenericFile.audit(version, true)
  end


  def self.audit(version, force = false)
    logger.debug "***AUDIT*** log for #{version.inspect}"
    latest_audit = self.find(version.pid).logs(version.dsid).first
    unless force
      unless GenericFile.needs_audit?(version, latest_audit)
         return latest_audit
      end
    end
    job = AuditJob.new(User.current, version.pid, version.dsid, version.versionID)
    #job.perform
    Delayed::Job.enqueue(job, :queue => 'audit')

    # run the find just incase the job has finished already
    latest_audit = self.find(version.pid).logs(version.dsid).first
    latest_audit = ChecksumAuditLog.new(:pass=>NO_RUNS, :pid=>version.pid, :dsid=>version.dsid, :version=>version.versionID) unless latest_audit
    return latest_audit
  end

  def self.needs_audit?(version, latest_audit)
    if latest_audit and latest_audit.updated_at
      logger.debug "***AUDIT*** last audit = #{latest_audit.updated_at.to_date}"
      days_since_last_audit = (DateTime.now - latest_audit.updated_at.to_date).to_i
      logger.debug "***AUDIT*** days since last audit: #{days_since_last_audit}"
      if days_since_last_audit < Rails.application.config.max_days_between_audits
        logger.debug "***AUDIT*** No audit needed for #{version.pid} #{version.versionID} (#{latest_audit.updated_at})"
        return false
      end
    else
      logger.warn "***AUDIT*** problem with audit log!"
    end
    logger.info "***AUDIT*** Audit needed for #{version.pid} #{version.versionID}"
    true
  end

  def self.audit_everything(force = false)
    GenericFile.find(:all, :rows => GenericFile.count).each do |gf|
      gf.per_version do |ver|
        GenericFile.audit(ver, force)
      end
    end
  end

  def self.audit_everything!
    GenericFile.audit_everything(true)
  end

  def self.run_audit(version)
    if version.dsChecksumValid
      logger.info "***AUDIT*** Audit passed for #{version.pid} #{version.versionID}"
      passing = true
      ChecksumAuditLog.prune_history(version)
    else
      logger.warn "***AUDIT*** Audit failed for #{version.pid} #{version.versionID}"
      passing = false
    end
    return ChecksumAuditLog.create!(:pass=>passing, :pid=>version.pid,
                             :dsid=>version.dsid, :version=>version.versionID)  
  end


  private 
  

  def permission_hash
    old_perms = self.permissions
    user_perms =  {}
    old_perms.select{|r| r[:type] == 'user'}.each do |r|
      user_perms[r[:name]] = r[:access]
    end
    user_perms
    group_perms =  {}
    old_perms.select{|r| r[:type] == 'group'}.each do |r|
      group_perms[r[:name]] = r[:access]
    end
    {'person'=>user_perms, 'group'=>group_perms}
  end
end
