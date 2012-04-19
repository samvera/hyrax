require "psu-customizations"

class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
  has_file_datastream :type => FileContentDatastream

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

  def GenericFile.audit!(version)
    GenericFile.audit(version, true)
  end

  def GenericFile.audit(version, force = false)
    logger.debug "***AUDIT*** log for #{version.inspect}"
    audit_log = ChecksumAuditLog.get_audit_log(version)
    unless force
      return unless GenericFile.needs_audit?(version, audit_log)
    end
    if version.dsChecksumValid
      logger.info "***AUDIT*** Audit passed for #{version.pid} #{version.versionID}"
      audit_log.pass = true
    else
      logger.warn "***AUDIT*** Audit failed for #{version.pid} #{version.versionID}"
      audit_log.pass = false
    end
    audit_log.save
  end

  def GenericFile.needs_audit?(version, audit_log)
    if audit_log and audit_log.updated_at
      logger.debug "***AUDIT*** audit log properly configured"
      logger.debug "***AUDIT*** last audit = #{audit_log.updated_at.to_date}"
      days_since_last_audit = (DateTime.now - audit_log.updated_at.to_date).to_i
      logger.debug "***AUDIT*** days since last audit: #{days_since_last_audit}"
      if days_since_last_audit < Rails.application.config.max_days_between_audits
        logger.debug "***AUDIT*** No audit needed for #{version.pid} #{version.versionID} (#{audit_log.updated_at})"
        return false
      end
    else
      logger.warn "***AUDIT*** problem with audit log!"
    end
    logger.info "***AUDIT*** Audit needed for #{version.pid} #{version.versionID}"
    true
  end

  def per_version(&block)
    self.datastreams.each do |dsid, ds|
      ds.versions.each do |ver|
        yield block.call(ver)
      end
    end
  end

  def audit
    self.per_version do |ver| 
      GenericFile.audit!
    end
  end

  def GenericFile.audit_everything
    GenericFile.find(:all).each do |gf|
      gf.per_version do |ver|
        GenericFile.audit
      end
    end
  end
end
