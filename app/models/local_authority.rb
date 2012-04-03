require 'rdf'

class LocalAuthority < ActiveRecord::Base
  has_and_belongs_to_many :domain_terms
  has_many :local_authority_entries

  def self.harvest_rdf(name, sources, format = :ntriples, predicate = RDF::SKOS.prefLabel)
    return unless self.where(:name => name).empty?
    authority = self.create(:name => name)
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

  def self.register_vocabulary(model, term, name)
    model = model.to_s.sub(/RDFDatastream$/, '').underscore.pluralize
    authority = self.where(:name => name)
    return if authority.empty?
    domain_term = DomainTerm.find_or_create_by_model_and_term(:model => model, :term => term)
    return if domain_term.local_authorities.include? authority
    domain_term.local_authorities << authority
  end
end
