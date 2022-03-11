# frozen_string_literal: true

module Hyrax
  class FileSet
    ##
    # This module points the FileSet to the location of the technical metadata.
    # By default, the file holding the metadata is +:original_file+ and the terms
    # are listed under +.characterization_terms+.
    #
    # Implementations may define their own terms or use a different source file, but
    # any terms must be set on the +.characterization_proxy+ by the
    # +Hydra::Works::CharacterizationService+.
    #
    # @example
    #   class MyFileSet
    #     include Hyrax::FileSetBehavior
    #   end
    #
    #   MyFileSet.characterization_proxy = :master_file
    #   MyFileSet.characterization_terms = [:term1, :term2, :term3]
    #
    module Characterization
      extend ActiveSupport::Concern

      included do
        class_attribute :characterization_terms, :characterization_proxy
        self.characterization_terms = [
          :format_label, :file_size, :height, :width, :filename, :well_formed,
          :page_count, :file_title, :last_modified, :original_checksum,
          :duration, :sample_rate, :alpha_channels
        ]
        self.characterization_proxy = Hyrax.config.characterization_proxy

        delegate(*characterization_terms, to: :characterization_proxy)

        def characterization_proxy
          send(self.class.characterization_proxy) || NullCharacterizationProxy.new
        end

        def characterization_proxy?
          !characterization_proxy.is_a?(NullCharacterizationProxy)
        end

        def mime_type
          @mime_type ||= characterization_proxy.mime_type
        end
      end

      class NullCharacterizationProxy
        def method_missing(*_args)
          []
        end

        def respond_to_missing?(_method_name, _include_private = false)
          super
        end

        def mime_type; end
      end

      # Add Alpha Channels to the Schema
      class AlphaChannelsSchema < ActiveTriples::Schema
        property :alpha_channels, predicate: ::RDF::URI.new('http://vocabulary.samvera.org/ns#alphaChannels')
      end

      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas << AlphaChannelsSchema

      # Add file_set_id for Valkyrie support.
      class FileSetIdSchema < ActiveTriples::Schema
        property :file_set_id, predicate: ::RDF::URI.new('http://vocabulary.samvera.org/ns#fileSetId')
      end
      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas << FileSetIdSchema
    end
  end
end
