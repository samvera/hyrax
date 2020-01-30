# frozen_string_literal: true

module Hyrax
  module Characterization
    ##
    # @api public
    class FileSetDescription
      include Hydra::Works::MimeTypes

      ##
      # @!attribute [rw] file_set
      #   @return [Hyrax::FileSet]
      attr_accessor :file_set

      delegate :mime_type, to: :primary_file

      ##
      # @param [Hyrax::FileSet] file_set
      # @param [Symbol] primary_file  a symbol mapping to the file_set member
      #   used for characterization
      def initialize(file_set:, primary_file: :original_file)
        self.file_set = file_set

        @primary_file_type_uri =
          Hyrax::FileMetadata::Use.uri_for(use: primary_file)
      end

      ##
      # @api public
      # @return [Hyrax::FileMetadata] the member file to use for characterization
      def primary_file
        queries.find_many_file_metadata_by_use(resource: file_set, use: @primary_file_type_uri).first ||
          Hyrax::FileMetadata.new
      end

      private

        ##
        # @api private
        def queries
          Hyrax.custom_queries
        end
    end
  end
end
