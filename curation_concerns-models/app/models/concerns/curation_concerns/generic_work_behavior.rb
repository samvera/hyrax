module CurationConcerns::GenericWorkBehavior
  extend ActiveSupport::Concern

  include Hydra::Works::GenericWorkBehavior
  include ::CurationConcerns::HumanReadableType
  include CurationConcerns::Noid
  include CurationConcerns::Permissions
  include CurationConcerns::Serializers
  include Hydra::WithDepositor
  include Solrizer::Common
  include ::CurationConcerns::HasRepresentative
  include ::CurationConcerns::WithGenericFiles
  include Hydra::AccessControls::Embargoable

  included do
    property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
    class_attribute :human_readable_short_description
  end

  module ClassMethods
    def indexer
      CurationConcerns::GenericWorkIndexingService
    end
  end

  def to_s
    title.join(', ')
  end

  # Returns a string identifying the path associated with the object. ActionPack uses this to find a suitable partial to represent the object.
  def to_partial_path
    "curation_concerns/#{super}"
  end

  def can_be_member_of_collection?(_collection)
    true
  end
end
