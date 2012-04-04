require 'rdf'

class LocalAuthority < ActiveRecord::Base
  has_and_belongs_to_many :domain_terms
  has_many :local_authority_entries

  def self.harvest_rdf(name, sources, opts = {})
    return unless self.where(:name => name).empty?
    authority = self.create(:name => name)
    format = opts.fetch(:format, :ntriples)
    predicate = opts.fetch(:predicate, RDF::SKOS.prefLabel)
    sources.each do |uri|
      puts "harvesting #{uri}"
      RDF::Reader.open(uri, :format => format) do |reader|
        reader.each_statement do |statement|
          if statement.predicate == predicate
            authority.local_authority_entries.create(:label => statement.object.to_s,
                                                     :uri => statement.subject.to_s)
          end
        end
      end
    end
  end

  def self.harvest_tsv(name, sources, opts = {})
    return unless self.where(:name => name).empty?
    authority = self.create(:name => name)
    prefix = opts.fetch(:prefix, "")
    sources.each do |uri|
      puts "harvesting #{uri}"
      open(uri) do |f|
        f.each_line do |tsv|
          fields = tsv.split(/\t/)
          authority.local_authority_entries.create(:uri => "#{prefix}#{fields[0]}/",
                                                   :label => fields[2])
        end
      end
    end
  end

  def self.register_vocabulary(model, term, name)
    authority = self.where(:name => name)
    return if authority.empty?
    model = model.to_s.sub(/RDFDatastream$/, '').underscore.pluralize
    domain_term = DomainTerm.find_or_create_by_model_and_term(:model => model, :term => term)
    return if domain_term.local_authorities.include? authority
    domain_term.local_authorities << authority
  end
end
