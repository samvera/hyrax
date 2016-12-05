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
  include CurationConcerns::InAdminSet
  include Hydra::AccessControls::Embargoable
  include GlobalID::Identification
  include CurationConcerns::NestedWorks
  include CurationConcerns::Suppressible

  included do
    property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
    class_attribute :human_readable_short_description, :indexer
    self.indexer = CurationConcerns::WorkIndexer
  end

  module ClassMethods
    # This governs which partial to draw when you render this type of object
    def _to_partial_path #:nodoc:
      @_to_partial_path ||= begin
        element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
        collection = ActiveSupport::Inflector.tableize(name)
        "curation_concerns/#{collection}/#{element}".freeze
      end
    end
  end
end
