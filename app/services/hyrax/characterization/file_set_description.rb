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
        @primary_file = primary_file
      end

      ##
      # @api public
      # @return [Hyrax::FileMetadata] the member file to use for characterization
      def primary_file
        files.find { |f| f.used_for?(@primary_file) } || Hyrax::FileMetadata.new
      end

      private

        ##
        # @api private
        def files
          @__files__ ||= Hyrax.query_service.custom_queries.find_files(file_set: file_set)
        end
    end
  end
end
