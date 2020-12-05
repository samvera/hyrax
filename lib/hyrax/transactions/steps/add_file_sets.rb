# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds a Hyrax::FileSet
      #
      # @see https://wiki.lyrasis.org/display/samvera/Hydra::Works+Shared+Modeling
      class AddFileSets
        include Dry::Monads[:result]

        ##
        # @param [Class] handler
        def initialize(handler: Hyrax::WorkUploadsHandler)
          @handler = handler
        end

        ##
        # @param [Hyrax::Work] obj
        # @param [Enumerable<UploadedFile>] uploaded_files
        #
        # @return [Dry::Monads::Result]
        def call(obj, uploaded_files: [])
          if @handler.new(work: obj).add(files: uploaded_files).attach
            Success(obj)
          else
            Failure[:failed_to_attach_file_sets, uploaded_files]
          end
        end
      end
    end
  end
end
