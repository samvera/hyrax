class LocalAuthority < ActiveRecord::Base
  # TODO: we should add an index on this join table and remove the uniq query
  has_and_belongs_to_many :domain_terms, -> { uniq }
  has_many :local_authority_entries

  def self.harvest_rdf(name, sources, opts = {})
    return unless where(name: name).empty?
    authority = create(name: name)
    format = opts.fetch(:format, :ntriples)
    predicate = opts.fetch(:predicate, ::RDF::Vocab::SKOS.prefLabel)
    entries = extract_harvestable_rdf_entries_from(sources, authority, predicate, format)
    import_or_save!(entries)
  end

  def self.extract_harvestable_rdf_entries_from(sources, authority, predicate, format)
    entries = []
    sources.each do |uri|
      ::RDF::Reader.open(uri, format: format) do |reader|
        reader.each_statement do |statement|
          next unless statement.predicate == predicate
          entries << LocalAuthorityEntry.new(local_authority: authority,
                                             label: statement.object.to_s,
                                             uri: statement.subject.to_s)
        end
      end
    end
    entries
  end
  private_class_method :extract_harvestable_rdf_entries_from

  def self.harvest_tsv(name, sources, opts = {})
    return unless where(name: name).empty?
    authority = create(name: name)
    prefix = opts.fetch(:prefix, "")
    entries = extract_harvestable_tsv_entries_from(sources, authority, prefix)
    import_or_save!(entries)
  end

  def self.extract_harvestable_tsv_entries_from(sources, authority, prefix)
    entries = []
    sources.each do |uri|
      open(uri) do |f|
        f.each_line do |tsv|
          fields = tsv.split(/\t/)
          entries << LocalAuthorityEntry.new(local_authority: authority,
                                             uri: "#{prefix}#{fields[0]}/",
                                             label: fields[2])
        end
      end
    end
    entries
  end
  private_class_method :extract_harvestable_tsv_entries_from

  def self.import_or_save!(entries)
    if LocalAuthorityEntry.respond_to?(:import)
      LocalAuthorityEntry.import(entries)
    else
      entries.each(&:save!)
    end
  end
  private_class_method :import_or_save!

  # @param [String] model_name the plural name for the model, (e.g. 'generic_works')
  # @param [String] term the field name
  # @param [String] name the vocabulary name
  def self.register_vocabulary(model_name, term, name)
    authority = find_by_name(name)
    if authority.blank?
      Rails.logger.warn "Unable to find a local authority for #{name} in the database. You may want to `LocalAuthority.harvest_rdf(\"#{name}\", [\"path/to/rdf.nt\"])' or `LocalAuthority.harvest_tsv(\"#{name}\", [\"path/to/data.tsv\"])'"
      return
    end
    domain_term = DomainTerm.find_or_create_by(model: model_name, term: term)
    return if domain_term.local_authorities.include? authority
    domain_term.local_authorities << authority
  end

  def self.entries_by_term(model, term, query)
    return if query.empty?
    low_query = query.downcase
    hits = []
    # move lc_subject into it's own table since being part of the usual structure caused it to be too slow.
    # When/if we move to having multiple dictionaries for subject we will need to also do a check for the appropriate dictionary.
    if term == 'subject' && model == 'generic_works' # and local_authoritiy = lc_subject
      sql = SubjectLocalAuthorityEntry.where("lowerLabel like ?", "#{low_query}%").select("label, url").limit(25).to_sql
      SubjectLocalAuthorityEntry.find_by_sql(sql).each do |hit|
        hits << { uri: hit.url, label: hit.label }
      end
    else
      dterm = DomainTerm.find_by(model: model, term: term)
      if dterm
        authorities = dterm.local_authorities.collect(&:id).uniq
        sql = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("lower(label) like ?", "#{low_query}%").select("label, uri").limit(25).to_sql
        LocalAuthorityEntry.find_by_sql(sql).each do |hit|
          hits << { uri: hit.uri, label: hit.label }
        end
      end
    end
    hits
  end
end
