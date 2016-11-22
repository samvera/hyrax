module CurationConcerns::WorkBehavior
  extend ActiveSupport::Concern

  include Hydra::Works::WorkBehavior
  include Sufia::HumanReadableType
  include Sufia::Noid
  include Sufia::Permissions
  include Sufia::Serializers
  include Hydra::WithDepositor
  include Solrizer::Common
  include Sufia::HasRepresentative
  include Sufia::WithFileSets
  include Sufia::Naming
  include Sufia::RequiredMetadata
  include Sufia::InAdminSet
  include Hydra::AccessControls::Embargoable
  include GlobalID::Identification
  include Sufia::NestedWorks
  include Sufia::Publishable

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
