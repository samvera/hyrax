class GenericFile < ActiveFedora::Base
  include ActiveModel::Validations::HelperMethods
  include ActiveFedora::Validations
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include ScholarSphere::ModelMethods
  include ScholarSphere::Noid

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => GenericFileRdfDatastream
  has_metadata :name => "properties", :type => PropertiesDatastream
  has_metadata :name => "rightsMetadata", :type => ParanoidRightsDatastream
  has_file_datastream :name => "content", :type => FileContentDatastream
  has_file_datastream :name => "thumbnail", :type => FileContentDatastream

  belongs_to :batch, :property => :is_part_of

  delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:date_uploaded, :date_modified], :unique => true
  delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                              :contributor, :title, :tag, :description, :rights,
                              :publisher, :date_created, :subject, :format,
                              :resource_type, :identifier, :language]
  delegate :mime_type, :to => :characterization, :unique => true
  delegate_to :characterization, [:format_label, :file_size, :last_modified,
                                  :filename, :original_checksum, :rights_basis,
                                  :copyright_basis, :copyright_note,
                                  :well_formed, :valid, :status_message,
                                  :file_title, :file_author, :page_count,
                                  :file_language, :word_count, :character_count,
                                  :paragraph_count, :line_count, :table_count,
                                  :graphics_count, :byte_order, :compression,
                                  :width, :height, :color_space, :profile_name,
                                  :profile_version, :orientation, :color_map,
                                  :image_producer, :capture_device,
                                  :scanning_software, :exif_version,
                                  :gps_timestamp, :latitude, :longitude,
                                  :character_set, :markup_basis,
                                  :markup_language, :duration, :bit_depth,
                                  :sample_rate, :channels, :data_format, :offset]

  around_save :characterize_if_changed
  validate :paranoid_permissions


  NO_RUNS = 999

  #make sure the terms of service is present and set to 1 before saving
  # note GenericFile.create will no longer save a GenericFile as the terms_of_service will not be set
  terms_of_service = nil
  validates_acceptance_of :terms_of_service, :allow_nil => false

  # set the terms of service on create so an empty generic file can be created
  #before_validation(:on => :create) do
  #  logger.info "!!!! Before create !!!!"
  #  self.terms_of_service = '1'
  #end

  def persistent_url
    "#{ScholarSphere::Application.config.persistent_hostpath}#{noid}"
  end

  def paranoid_permissions
    # let the rightsMetadata ds make this determination
    # - the object instance is passed in for easier access to the props ds
    rightsMetadata.validate(self)
  end

  ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
  def permissions=(params)
    perm_hash = permission_hash
    params[:new_user_name].each { |name, access| perm_hash['person'][name] = access } if params[:new_user_name].present?
    params[:new_group_name].each { |name, access| perm_hash['group'][name] = access } if params[:new_group_name].present?

    params[:user].each { |name, access| perm_hash['person'][name] = access} if params[:user]
    params[:group].each { |name, access| perm_hash['group'][name] = access} if params[:group]
    rightsMetadata.update_permissions(perm_hash)
  end

  def characterize_if_changed
    content_changed = self.content.changed?
    yield
    #logger.debug "DOING CHARACTERIZE ON #{self.pid}"
    Resque.enqueue(CharacterizeJob, self.pid) if content_changed
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
    # TODO: if we can figure out how to do video (ffmpeg?)
    #elsif ["video/mpeg", "video/mp4"].include? self.mime_type
    end
  end

  # redefine find so that it sets the terms of service
  def self.find(args, opts={})
    gf = super
    # use the field type to see if the return will be one item or multiple
    if args.is_a? String
      gf.terms_of_service = '1'
    else
      gf.each {|f| f.terms_of_service = '1'}
    end
    return gf
  end

  def create_pdf_thumbnail
    retryCnt = 0
    stat = false;
    for retryCnt in 1..3
      begin
        pdf = Magick::ImageList.new
        pdf.from_blob(content.content)
        first = pdf.to_a[0]
        first.format = "PNG"
        thumb = first.scale(338, 493)
        self.thumbnail.content = thumb.to_blob { self.format = "PNG" }
        #logger.debug "Has the content changed before saving? #{self.content.changed?}"
        self.terms_of_service = '1'
        stat = self.save
        break
      rescue => e
        logger.warn "Rescued an error #{e.inspect} retry count = #{retryCnt}"
        sleep 1
      end
    end
    return stat
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
    #logger.debug "Has the content before saving? #{self.content.changed?}"
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
        term.start_with? "generic_file__" and !['type', 'behaviors'].include? term.split('__').last
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

  # MIME: 'application/x-endnote-refer'
  def export_as_endnote
    end_note_format = {
      '%T' => [:title, lambda { |x| x.first }],
      '%Q' => [:title, lambda { |x| x.drop(1) }],
      '%A' => [:creator],
      '%C' => [:publication_place],
      '%D' => [:date_created],
      '%8' => [:date_uploaded],
      '%E' => [:contributor],
      '%I' => [:publisher],
      '%J' => [:series_title],
      '%@' => [:isbn],
      '%U' => [:related_url],
      '%7' => [:edition_statement],
      '%R' => [:persistent_url],
      '%X' => [:description],
      '%G' => [:language],
      '%[' => [:date_modified],
      '%9' => [:resource_type],
      '%~' => ScholarSphere::Application.config.application_name,
      '%W' => 'Penn State University'
    }
    text = []
    text << "%0 GenericFile"
    end_note_format.each do |endnote_key, mapping|
      if mapping.is_a? String
        values = [mapping]
      else
        values = self.send(mapping[0]) if self.respond_to? mapping[0]
        values = mapping[1].call(values) if mapping.length == 2
        values = [values] unless values.is_a? Array
      end
      next if values.empty? or values.first.nil?
      spaced_values = values.join("; ")
      text << "#{endnote_key} #{spaced_values}"
    end
    return text.join("\n")
  end

  # MIME type: 'application/x-openurl-ctx-kev'
  def export_as_openurl_ctx_kev
    export_text = []
    export_text << "url_ver=Z39.88-2004&ctx_ver=Z39.88-2004&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator"
    field_map = {
      :title => 'title',
      :creator => 'creator',
      :subject => 'subject',
      :description => 'description',
      :publisher => 'publisher',
      :contributor => 'contributor',
      :date_created => 'date',
      :resource_type => 'format',
      :identifier => 'identifier',
      :language => 'language',
      :tag => 'relation',
      :based_near => 'coverage',
      :rights => 'rights'
    }
    field_map.each do |element, kev|
      values = self.send(element)
      next if values.empty? or values.first.nil?
      values.each do |value|
        export_text << "rft.#{kev}=#{CGI::escape(value)}"
      end
    end
    export_text.join('&') unless export_text.blank?
  end

  def export_as_apa_citation
    text = ''
    authors_list = []
    authors_list_final = []

    #setup formatted author list
    authors = get_author_list
    authors.each do |author|
      next if author.blank?
      authors_list.push(abbreviate_name(author))
    end
    authors_list.each do |author|
      if author == authors_list.first #first
        authors_list_final.push(author.strip)
      elsif author == authors_list.last #last
        authors_list_final.push(", &amp; " + author.strip)
      else #all others
        authors_list_final.push(", " + author.strip)
      end
    end
    text << authors_list_final.join
    unless text.blank?
      if text[-1,1] != "."
        text << ". "
      else
        text << " "
      end
    end
    # Get Pub Date
    text << "(" + setup_pub_date + "). " unless setup_pub_date.nil?

    # setup title info
    title_info = setup_title_info
    text << "<i>" + title_info + "</i> " unless title_info.nil?

    # Publisher info
    text << setup_pub_info unless setup_pub_info.nil?
    unless text.blank?
      if text[-1,1] != "."
        text += "."
      end
    end
    text.html_safe
  end

  def export_as_mla_citation
    text = ''
    authors_final = []

    #setup formatted author list
    authors = get_author_list

    if authors.length < 4
      authors.each do |author|
        if author == authors.first #first
          authors_final.push(author)
        elsif author == authors.last #last
          authors_final.push(", and " + name_reverse(author) + ".")
        else #all others
          authors_final.push(", " + name_reverse(author))
        end
      end
      text << authors_final.join
      unless text.blank?
        if text[-1,1] != "."
          text << ". "
        else
          text << " "
        end
      end
    else
      text << authors.first + ", et al. "
    end
    # setup title
    title_info = setup_title_info
    text << "<i>" + mla_citation_title(title_info) + "</i> " unless title.blank?

    # Publication
    text << setup_pub_info + ", " unless setup_pub_info.nil?

    # Get Pub Date
    text << setup_pub_date unless setup_pub_date.nil?
    if text[-1,1] != "."
      text << "." unless text.blank?
    end
    text.html_safe
  end

  def export_as_chicago_citation
    author_text = ""
    authors = get_all_authors
    unless authors.blank?
      if authors.length > 10
        authors.each_with_index do |author, index|
          if index < 7
            if index == 0
              author_text << "#{author}"
              if author.ends_with?(",")
                author_text << " "
              else
                author_text << ", "
              end
            else
              author_text << "#{name_reverse(author)}, "
            end
          end
        end
        author_text << " et al."
      elsif authors.length > 1
        authors.each_with_index do |author,index|
          if index == 0
            author_text << "#{author}"
            if author.ends_with?(",")
              author_text << " "
            else
              author_text << ", "
            end
          elsif index + 1 == authors.length
            author_text << "and #{name_reverse(author)}."
          else
            author_text << "#{name_reverse(author)}, "
          end
        end
      else
        author_text << authors.first
      end
    end
    title_info = ""
    title_info << citation_title(clean_end_punctuation(CGI::escapeHTML(title.first)).strip) unless title.blank?

    pub_info = ""
    place = self.based_near.first
    publisher = self.publisher.first
    unless place.blank?
      place = CGI::escapeHTML(place)
      pub_info << place
      pub_info << ": " unless publisher.blank?
    end
    unless publisher.blank?
      publisher = CGI::escapeHTML(publisher)
      pub_info << publisher
      pub_info << ", " unless setup_pub_date.nil?
    end
    unless setup_pub_date.nil?
      pub_info << setup_pub_date
    end

    citation = ""
    citation << "#{author_text} " unless author_text.blank?
    citation << "<i>#{title_info}.</i> " unless title_info.blank?
    citation << "#{pub_info}." unless pub_info.blank?
    citation.html_safe
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
      return 'Some audits have not been run, but the ones run were '+ ((result)? 'passing' : 'failing') + '.'
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
    #logger.debug "***AUDIT*** log for #{version.inspect}"
    latest_audit = self.find(version.pid).logs(version.dsid).first
    unless force
      return latest_audit unless GenericFile.needs_audit?(version, latest_audit)
    end
    Resque.enqueue(AuditJob, version.pid, version.dsid, version.versionID)

    # run the find just incase the job has finished already
    latest_audit = self.find(version.pid).logs(version.dsid).first
    latest_audit = ChecksumAuditLog.new(:pass=>NO_RUNS, :pid=>version.pid, :dsid=>version.dsid, :version=>version.versionID) unless latest_audit
    return latest_audit
  end

  def self.needs_audit?(version, latest_audit)
    if latest_audit and latest_audit.updated_at
      #logger.debug "***AUDIT*** last audit = #{latest_audit.updated_at.to_date}"
      days_since_last_audit = (DateTime.now - latest_audit.updated_at.to_date).to_i
      #logger.debug "***AUDIT*** days since last audit: #{days_since_last_audit}"
      if days_since_last_audit < Rails.application.config.max_days_between_audits
        #logger.debug "***AUDIT*** No audit needed for #{version.pid} #{version.versionID} (#{latest_audit.updated_at})"
        return false
      end
    else
      logger.warn "***AUDIT*** problem with audit log!"
    end
    #logger.info "***AUDIT*** Audit needed for #{version.pid} #{version.versionID}"
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
      #logger.info "***AUDIT*** Audit passed for #{version.pid} #{version.versionID}"
      passing = 1
      ChecksumAuditLog.prune_history(version)
    else
      logger.warn "***AUDIT*** Audit failed for #{version.pid} #{version.versionID}"
      passing = 0
    end
    check = ChecksumAuditLog.create!(:pass=>passing, :pid=>version.pid,
                                     :dsid=>version.dsid, :version=>version.versionID)
    return check
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

  def setup_pub_date
    first_date = self.date_created.first
    unless first_date.blank?
      first_date = CGI::escapeHTML(first_date)
      date_value = first_date.gsub(/[^0-9|n\.d\.]/, "")[0,4]
      return nil if date_value.nil?
    end
    clean_end_punctuation(date_value) if date_value
  end

  def setup_pub_info
    text = ''
    place = self.based_near.first
    publisher = self.publisher.first
    unless place.blank?
      place = CGI::escapeHTML(place)
      text << place
      text << ": " unless publisher.blank?
    end
    unless publisher.blank?
      publisher = CGI::escapeHTML(publisher)
      text << publisher
    end
    return nil if text.strip.blank?
    clean_end_punctuation(text.strip)
  end

  def mla_citation_title(text)
    no_upcase = ["a","an","and","but","by","for","it","of","the","to","with"]
    new_text = []
    word_parts = text.split(" ")
    word_parts.each do |w|
      if !no_upcase.include? w
        new_text.push(w.capitalize)
      else
        new_text.push(w)
      end
    end
    new_text.join(" ")
  end

  def citation_title(title_text)
    prepositions = ["a","about","across","an","and","before","but","by","for","it","of","the","to","with","without"]
    new_text = []
    title_text.split(" ").each_with_index do |word,index|
      if (index == 0 and word != word.upcase) or (word.length > 1 and word != word.upcase and !prepositions.include?(word))
        # the split("-") will handle the capitalization of hyphenated words
        new_text << word.split("-").map!{|w| w.capitalize }.join("-")
      else
        new_text << word
      end
    end
    new_text.join(" ")
  end

  def setup_title_info
    text = ''
    title = self.title.first
    unless title.blank?
      title = CGI::escapeHTML(title)
      title_info = clean_end_punctuation(title.strip)
      text << title_info
    end

    return nil if text.strip.blank?
    clean_end_punctuation(text.strip) + "."
  end

  def clean_end_punctuation(text)
    if [".",",",":",";","/"].include? text[-1,1]
      return text[0,text.length-1]
    end
    text
  end

  def get_author_list
    self.creator.map { |author| clean_end_punctuation(CGI::escapeHTML(author)) }.uniq
  end

  def get_all_authors
    authors = self.creator
    return authors.empty? ? nil : authors.map { |author| CGI::escapeHTML(author) }
  end

  def abbreviate_name(name)
    abbreviated_name = ''
    name = name.join('') if name.is_a? Array
    # make sure we handle "Cher" correctly
    return name if !name.include?(' ') and !name.include?(',')
    surnames_first = name.include?(',')
    delimiter = surnames_first ? ', ' : ' '
    name_segments = name.split(delimiter)
    given_names = surnames_first ? name_segments.last.split(' ') : name_segments.first.split(' ')
    surnames = surnames_first ? name_segments.first.split(' ') : name_segments.last.split(' ')
    abbreviated_name << surnames.join(' ')
    abbreviated_name << ', '
    abbreviated_name << given_names.map { |n| "#{n[0]}." }.join if given_names.is_a? Array
    abbreviated_name << "#{given_names[0]}." if given_names.is_a? String
    abbreviated_name
  end

  def name_reverse(name)
    name = clean_end_punctuation(name)
    return name unless name =~ /,/
    temp_name = name.split(", ")
    return temp_name.last + " " + temp_name.first
  end
end
