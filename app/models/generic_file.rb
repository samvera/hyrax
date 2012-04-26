require "psu-customizations"

class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
  has_file_datastream :type => FileContentDatastream


  #handle_asynchronously :to_solr 

  belongs_to :batch, :property => "isPartOf"

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
  delegate :date_uploaded, :to => :descMetadata
  delegate :date_modified, :to => :descMetadata
  delegate :subject, :to => :descMetadata
  delegate :language, :to => :descMetadata
  delegate :date, :to => :descMetadata
  delegate :rights, :to => :descMetadata
  delegate :resource_type, :to => :descMetadata
  delegate :format, :to => :descMetadata
  delegate :identifier, :to => :descMetadata
  delegate :format_label, :to => :characterization
  delegate :mime_type, :to => :characterization
  delegate :file_size, :to => :characterization
  delegate :last_modified, :to => :characterization
  delegate :filename, :to => :characterization
  delegate :original_checksum, :to => :characterization
  delegate :well_formed, :to => :characterization
  delegate :file_title, :to => :characterization
  delegate :file_author, :to => :characterization
  delegate :page_count, :to => :characterization

  before_save :characterize

  ## Extract the metadata from the content datastream and record it in the characterization datastream
  def characterize
    if content.changed?
      characterization.content = content.extract_metadata
    end
  end
  
  def to_solr(solr_doc={})
    super(solr_doc)
    solr_doc["label_t"] = self.label
    solr_doc["noid_s"] = self.pid.split(":").last
    return solr_doc
  end
  
  def label=(new_label)
    @inner_object.label = new_label
    if self.title.empty?
      self.title = new_label
    end
  end

  def to_jq_upload
    {
      "name" => self.title,
      "size" => self.file_size,
      "url" => "/files/" + self.pid.split(":").last,
      "thumbnail_url" => self.pid,
      "delete_url" => "deleteme", # generic_file_path(:id => id),
      "delete_type" => "DELETE" 
    }
  end
  
  def get_terms
    @terms = []
    self.descMetadata.class.config[:predicate_mapping].each do |uri, mappings|
      mappings.keys.each do |term|
        @terms << term if term.to_s.start_with? "generic_file__" and not ['solrtype', 'solrbehaviors'].include? term.to_s.split('__').last
      end 
    end 
    @terms
  end

  def set_public_access(access_level)
    self.datastreams["rightsMetadata"].permissions({:group=>"public"}, access_level)
  end

  def logs(dsid)
    ChecksumAuditLog.where(:dsid=>dsid, :pid=>self.pid).order('created_at desc, id desc')
  end

  def audit!
    audit(true)
  end

  def audit_stat
      logs = audit(true)
      logger.info "*****"
      logger.info logs.inspect
      logger.info "*****"
      audit_results = logs.collect { |result| result["pass"] }
      logger.info "!*****"
      logger.info audit_results.inspect
      logger.info "!*****"
      result =audit_results.reduce(true) { |sum, value| sum && value }
      result
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

  def GenericFile.audit!(version)
    GenericFile.audit(version, true)
  end

  def GenericFile.audit(version, force = false)
    logger.debug "***AUDIT*** log for #{version.inspect}"
    latest_audit = self.find(version.pid).logs(version.dsid).first
    unless force
      return unless GenericFile.needs_audit?(version, latest_audit)
    end
    if version.dsChecksumValid
      logger.info "***AUDIT*** Audit passed for #{version.pid} #{version.versionID}"
      passing = true
      ChecksumAuditLog.prune_history(version)
    else
      logger.warn "***AUDIT*** Audit failed for #{version.pid} #{version.versionID}"
      passing = false
    end
    ChecksumAuditLog.create!(:pass=>passing, :pid=>version.pid,
                             :dsid=>version.dsid, :version=>version.versionID)
  end

  def GenericFile.needs_audit?(version, latest_audit)
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

  def GenericFile.audit_everything(force = false)
    GenericFile.find(:all).each do |gf|
      gf.per_version do |ver|
        GenericFile.audit(ver, force)
      end
    end
  end

  def GenericFile.audit_everything!
    GenericFile.audit_everything(true)
  end
end
