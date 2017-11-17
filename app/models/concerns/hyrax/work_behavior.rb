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
    include WithFileSets
    include Naming
    include CoreMetadata
    include InAdminSet
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

      attribute :embargo_id, Valkyrie::Types::ID.optional
      attribute :lease_id, Valkyrie::Types::ID.optional
    end

    # TODO: Move this into ActiveFedora
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

    # Set the current visibility to match what is described in the embargo.
    # @param embargo [Hyrax::Embargo] the embargo visibility to copy to this work.
    def assign_embargo_visibility(embargo)
      return unless embargo.embargo_release_date
      self.visibility = if embargo.active?
                          embargo.visibility_during_embargo
                        else
                          embargo.visibility_after_embargo
                        end
    end

    # Set the current visibility to match what is described in the lease.
    # @param lease [Hyrax::Lease] the lease visibility to copy to this work.
    def assign_lease_visibility(lease)
      return unless lease.lease_expiration_date
      self.visibility = if lease.active?
                          lease.visibility_during_lease
                        else
                          lease.visibility_after_lease
                        end
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
