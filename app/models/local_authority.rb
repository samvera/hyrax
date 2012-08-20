require 'rdf'
require 'rdf/rdfxml'

class LocalAuthority < ActiveRecord::Base
  has_and_belongs_to_many :domain_terms, :uniq=> true 
  has_many :local_authority_entries

  def self.harvest_rdf(name, sources, opts = {})
    return unless self.where(:name => name).empty?
    authority = self.create(:name => name)
    format = opts.fetch(:format, :ntriples)
    predicate = opts.fetch(:predicate, RDF::SKOS.prefLabel)
    entries = []
    sources.each do |uri|
      RDF::Reader.open(uri, :format => format) do |reader|
        reader.each_statement do |statement|
          if statement.predicate == predicate
            entries << LocalAuthorityEntry.new(:local_authority => authority,
                                               :label => statement.object.to_s,
                                               :uri => statement.subject.to_s)
          end
        end
      end
    end
    LocalAuthorityEntry.import entries
  end

  def self.harvest_tsv(name, sources, opts = {})
    return unless self.where(:name => name).empty?
    authority = self.create(:name => name)
    prefix = opts.fetch(:prefix, "")
    entries = []
    sources.each do |uri|
      open(uri) do |f|
        f.each_line do |tsv|
          fields = tsv.split(/\t/)
          entries << LocalAuthorityEntry.new(:local_authority => authority,
                                             :uri => "#{prefix}#{fields[0]}/",
                                             :label => fields[2])
        end
      end
    end
    LocalAuthorityEntry.import entries
  end

  def self.register_vocabulary(model, term, name)
    authority = self.find_by_name(name)
    return if authority.blank?
    model = model.to_s.sub(/RdfDatastream$/, '').underscore.pluralize
    domain_term = DomainTerm.find_or_create_by_model_and_term(:model => model, :term => term)
    return if domain_term.local_authorities.include? authority
    domain_term.local_authorities << authority
  end

  def self.entries_by_term(model, term, query)
    return if query.empty?
    lowQuery = query.downcase
    hits = []
    term = DomainTerm.where(:model => model, :term => term).first
    if term
      authorities = term.local_authorities.collect(&:id).uniq      
      sql = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("lower(label) like ?", "#{lowQuery}%").select("label, uri").limit(25).to_sql
      LocalAuthorityEntry.find_by_sql(sql).each do |hit|
        hits << {:uri => hit.uri, :label => hit.label}
      end
    end
    hits
  end
end
