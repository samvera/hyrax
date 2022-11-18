# frozen_string_literal: true
module Hyrax
  module WorkBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::WorkBehavior
    include HumanReadableType
    include Hyrax::Noid
    include Permissions
    include Serializers
    include Hydra::WithDepositor
    include HasRepresentative
    include HasRendering
    include WithFileSets
    include Naming
    include CoreMetadata
    include InAdminSet
    include Hyrax::Embargoable
    include GlobalID::Identification
    include NestedWorks
    include Suppressible
    include ProxyDeposit
    include Works::Metadata
    include WithEvents
    include(Hyrax::CollectionNesting) unless
      Hyrax.config.use_solr_graph_for_collection_nesting

    included do
      property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
      class_attribute :human_readable_short_description, :default_system_virus_scanner
      # TODO: do we need this line?
      self.indexer = WorkIndexer
      # Default VirusScanner, configurable for Hyrax work types
      self.default_system_virus_scanner = Hyrax::VirusScanner
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path # :nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}"
        end
      end
    end
  end
end
