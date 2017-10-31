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
    # include Hydra::AccessControls::Embargoable
    include GlobalID::Identification

    included do
      attr_accessor :file

      attribute :file_identifiers, Valkyrie::Types::Set
      attribute :member_ids, Valkyrie::Types::Array
    end

    def original_file
      return if member_ids.empty?
      # TODO: we should be checking the use predicate here
      Hyrax::Queries.find_by(id: member_ids.first)
    end

    def representative_id
      to_param
    end

    def thumbnail_id
      to_param
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      CatalogController.new.fetch(id).last
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
