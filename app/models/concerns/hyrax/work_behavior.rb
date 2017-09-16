module Hyrax
  module WorkBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::WorkBehavior
    include HumanReadableType
    include Hyrax::Noid
    include Permissions
    include Serializers
    include Hydra::WithDepositor
    include Solrizer::Common
    include HasRepresentative
    include WithFileSets
    include Naming
    include CoreMetadata
    include InAdminSet
    include Hydra::AccessControls::Embargoable
    include GlobalID::Identification
    include NestedWorks
    include Suppressible
    include ProxyDeposit
    include Works::Metadata
    include WithEvents
    include Hyrax::CollectionNesting

    included do
      property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
      class_attribute :human_readable_short_description
      # TODO: do we need this line?
      self.indexer = WorkIndexer
    end

    # TODO: Move this into ActiveFedora
    def etag
      raise "Unable to produce an etag for a unsaved object" unless persisted?
      ldp_source.head.etag
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path #:nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}".freeze
        end
      end
    end
  end
end
