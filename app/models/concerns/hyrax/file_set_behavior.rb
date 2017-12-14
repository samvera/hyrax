module Hyrax
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Hyrax::WithEvents
    # include Hydra::Works::FileSetBehavior
    include Hydra::Works::MimeTypes
    # include Hydra::Works::VirusCheck
    include Hyrax::FileSet::Characterization
    include Hydra::WithDepositor
    include Serializers
    include Hyrax::Noid
    include Hyrax::FileSet::Derivatives
    include Permissions
    include Hyrax::FileSet::BelongsToWorks
    include HumanReadableType
    include CoreMetadata
    include Hyrax::BasicMetadata
    include Naming
    include GlobalID::Identification

    included do
      attr_accessor :file

      attribute :member_ids, Valkyrie::Types::Array
      attribute :embargo_id, Valkyrie::Types::ID.optional
      attribute :lease_id, Valkyrie::Types::ID.optional

      delegate :width, :height, :mime_type, :size, to: :original_file, allow_nil: true
    end

    # @return [Hyrax::FileNode] with use Valkyrie::Vocab::PCDMUse.OriginalFile
    def original_file
      return if member_ids.empty?
      # TODO: we should be checking the use predicate here
      Hyrax::Queries.find_by(id: Valkyrie::ID.new(member_ids.first))
    end

    def representative_id
      to_param
    end

    def thumbnail_id
      to_param
    end

    # @return [Boolean] whether this instance is a Hydra::Works Collection.
    def collection?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works Generic Work.
    def work?
      false
    end

    # @return [Boolean] whether this instance is a Hydra::Works::FileSet.
    def file_set?
      true
    end

    def in_works
      Hyrax::Queries.find_inverse_references_by(resource: self, property: :member_ids)
    end
  end
end
