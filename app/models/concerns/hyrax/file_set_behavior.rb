module Hyrax
  module FileSetBehavior
    extend ActiveSupport::Concern
    include ActiveModel::Conversion # provides _to_partial_path
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
    include Embargoable
    include Leasable

    included do
      attr_accessor :file

      attribute :member_ids, Valkyrie::Types::Array
      attribute :embargo_id, Valkyrie::Types::ID.optional
      attribute :lease_id, Valkyrie::Types::ID.optional

      delegate :width, :height, :mime_type, :size, :format_label, :format_label=, to: :original_file, allow_nil: true
    end

    # @return [Hyrax::FileNode] with use Valkyrie::Vocab::PCDMUse.OriginalFile
    def original_file
      member_by(use: Valkyrie::Vocab::PCDMUse.OriginalFile)
    end

    def member_by(use:)
      return if member_ids.empty?
      Hyrax::Queries.find_members(resource: self, model: Hyrax::FileNode).find { |f| f.use.first == use }
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
