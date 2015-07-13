module CurationConcerns::GenericWorkBehavior
  extend ActiveSupport::Concern

  include Hydra::Works::GenericWorkBehavior
  include ::CurationConcerns::HumanReadableType
  include CurationConcerns::Noid
  include CurationConcerns::Permissions
  include CurationConcerns::Serializers
  include Hydra::WithDepositor
  include Hydra::Collections::Collectible
  include Solrizer::Common
  include ::CurationConcerns::HasRepresentative
  include ::CurationConcerns::WithGenericFiles
  include Hydra::AccessControls::Embargoable
  include ::CurationConcerns::WithEditors

  included do
    property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
    class_attribute :human_readable_short_description
    attr_accessor :files
  end

  module ClassMethods
    def indexer
      CurationConcerns::GenericWorkIndexingService
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc).tap do |solr_doc|
      Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)
    end
  end

  def as_rdf_object
    RDF::URI.new(internal_uri)
  end

  def to_s
    title.join(', ')
  end

  # Returns a string identifying the path associated with the object. ActionPack uses this to find a suitable partial to represent the object.
  def to_partial_path
    "curation_concern/#{super}"
  end

  def can_be_member_of_collection?(collection)
    collection == self ? false : true
  end

  protected

  def index_collection_ids(solr_doc)
    solr_doc[Solrizer.solr_name(:collection, :facetable)] ||= []
    solr_doc[Solrizer.solr_name(:collection)] ||= []
    self.collection_ids.each do |collection_id|
      collection_obj = ActiveFedora::Base.load_instance_from_solr(collection_id)
      if collection_obj.is_a?(Collection)
        solr_doc[Solrizer.solr_name(:collection, :facetable)] << collection_id
        solr_doc[Solrizer.solr_name(:collection)] << collection_id
      end
    end
    solr_doc
  end

end
