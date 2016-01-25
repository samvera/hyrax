module CurationConcerns::WorkBehavior
  extend ActiveSupport::Concern

  include Hydra::Works::WorkBehavior
  include CurationConcerns::HumanReadableType
  include CurationConcerns::Noid
  include CurationConcerns::Permissions
  include CurationConcerns::Serializers
  include Hydra::WithDepositor
  include Solrizer::Common
  include CurationConcerns::HasRepresentative
  include CurationConcerns::WithFileSets
  include CurationConcerns::Naming
  include CurationConcerns::RequiredMetadata
  include Hydra::AccessControls::Embargoable

  included do
    property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
    class_attribute :human_readable_short_description
  end

  module ClassMethods
    def indexer
      CurationConcerns::WorkIndexer
    end
  end

  def to_s
    if title.present?
      Array(title).join(' | ')
    else
      'No Title'
    end
  end
end
