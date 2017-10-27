module Hyrax
  module WorkBehavior
    extend ActiveSupport::Concern
    # include Hydra::Works::WorkBehavior
    include HumanReadableType
    include Hyrax::Noid
    include Permissions
    include Serializers
    include Hydra::WithDepositor
    include Solrizer::Common
    # include WithFileSets
    include Naming
    include CoreMetadata
    include InAdminSet
    # include Hydra::AccessControls::Embargoable
    include GlobalID::Identification
    include NestedWorks
    include Suppressible
    include ProxyDeposit
    include Works::Metadata
    include WithEvents

    included do
      # property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
      class_attribute :human_readable_short_description

      # The collections that contain this object (no order)
      attribute :member_of_collection_ids, Valkyrie::Types::Set

      # The FileSets and child works this work contains (in order)
      attribute :member_ids, Valkyrie::Types::Array

      # Points at an image file that displays this work.
      attribute :thumbnail_id, Valkyrie::Types::ID.optional
      # Points at a file that displays something about this work. Could be an image or a video.
      attribute :representative_id, Valkyrie::Types::ID.optional
    end

    # TODO: This can be removed when we upgrade to ActiveFedora 12.0
    def etag
      raise "Unable to produce an etag for a unsaved object" unless persisted?
      ldp_source.head.etag
    end

    # @return [Boolean] whether this instance is a Hydra::Works Collection.
    def collection?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      true
    end

    # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
    def file_set?
      false
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
