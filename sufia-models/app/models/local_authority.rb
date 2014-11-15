class LocalAuthority < ActiveRecord::Base

  # TODO we should add an index on this join table and remove the uniq query
  has_and_belongs_to_many :domain_terms, -> { uniq }
  
  has_many :local_authority_entries

  def self.harvest_rdf(name, sources, opts = {})
    return unless self.where(name: name).empty?
    authority = self.create(name: name)
    format = opts.fetch(:format, :ntriples)
    predicate = opts.fetch(:predicate, ::RDF::SKOS.prefLabel)
    entries = []
    sources.each do |uri|
      ::RDF::Reader.open(uri, format: format) do |reader|
        reader.each_statement do |statement|
          if statement.predicate == predicate
            entries << LocalAuthorityEntry.new(local_authority: authority,
                                               label: statement.object.to_s,
                                               uri: statement.subject.to_s)
          end
        end
      end
    end
    if LocalAuthorityEntry.respond_to? :import
      LocalAuthorityEntry.import entries
    else
      entries.each { |e| e.save! }
    end
  end

  def self.harvest_tsv(name, sources, opts = {})
    return unless self.where(name: name).empty?
    authority = self.create(name: name)
    prefix = opts.fetch(:prefix, "")
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
    if LocalAuthorityEntry.respond_to? :import
      LocalAuthorityEntry.import entries
    else
      entries.each { |e| e.save! }
    end
  end

  def self.register_vocabulary(model, term, name)
    authority = self.find_by_name(name)
    return if authority.blank?
    model = model.to_s.sub(/RdfDatastream$/, '').underscore.pluralize
    domain_term = DomainTerm.find_or_create_by(model: model, term: term)
    return if domain_term.local_authorities.include? authority
    domain_term.local_authorities << authority
  end

  def self.entries_by_term(model, term, query)
    return if query.empty?
    lowQuery = query.downcase
    hits = []
    # move lc_subject into it's own table since being part of the usual structure caused it to be too slow.  
    # When/if we move to having multiple dictionaries for subject we will need to also do a check for the appropriate dictionary. 
    if (term == 'subject' && model == 'generic_files') # and local_authoritiy = lc_subject 
        sql = SubjectLocalAuthorityEntry.where("lowerLabel like ?", "#{lowQuery}%").select("label, uri").limit(25).to_sql
        SubjectLocalAuthorityEntry.find_by_sql(sql).each do |hit|
          hits << {uri: hit.uri, label: hit.label}
        end
    else 
      dterm = DomainTerm.where(model: model, term: term).first
      if dterm
        authorities = dterm.local_authorities.collect(&:id).uniq      
        sql = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("lower(label) like ?", "#{lowQuery}%").select("label, uri").limit(25).to_sql
        LocalAuthorityEntry.find_by_sql(sql).each do |hit|
          hits << {uri: hit.uri, label: hit.label}
        end
      end
    end
    return hits
  end
end
