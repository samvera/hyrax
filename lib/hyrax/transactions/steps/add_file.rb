# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds a ?
      #
      # @see https://wiki.lyrasis.org/display/samvera/Hydra::Works+Shared+Modeling
      class AddFile
        include Dry::Monads[:result]

        ##
        # @param [Class] handler
        # def initialize(handler: Hyrax::WorkUploadsHandler)
        #   @handler = handler
        # end

        ##
        # @param [Hyrax::FileSet] obj
        # @param [UploadedFile] uploaded_file
        #
        # @return [Dry::Monads::Result]
        def call(obj, uploaded_file: nil)
          return Success(obj) if uploaded_file.nil?
          upload_result = uploaded_file.add_file_set!(obj)
          save_result = Hyrax.persister.save(resource: obj)

          return Success(obj) if upload_result && save_result

          Failure[:failed_to_attach_file, uploaded_file]
        end
      end
    end
  end
end
