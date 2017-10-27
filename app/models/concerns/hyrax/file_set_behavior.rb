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
  end
end
