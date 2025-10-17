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
        # @param [Enumerable<Hash>] file_set_params or nil
        #
        # @return [Dry::Monads::Result]
        def call(obj, uploaded_files: [], file_set_params: [])
          return Success(obj) if uploaded_files.empty? && file_set_params.blank? # Skip if no files to attach
          if @handler.new(work: obj).add(files: uploaded_files, file_set_params: file_set_params).attach
            reloaded_work = Hyrax.query_service.find_by(id: obj.id)
            raise "Can't refind the work" unless reloaded_work
            file_sets = reloaded_work.member_ids.map do |member|
              Hyrax.query_service.find_by(id: member) if Hyrax.query_service.find_by(id: member).is_a? Hyrax::FileSet
            end.compact

            # TODO: improve queries - Non performant to perform single queries. Perhaps queries ids then reject.
            Hyrax::LeaseManager.create_or_update_lease_on_members(file_sets, reloaded_work) if reloaded_work.lease
            Hyrax::EmbargoManager.create_or_update_embargo_on_members(file_sets, reloaded_work) if reloaded_work.embargo
            Success(reloaded_work)
          else
            Failure[:failed_to_attach_file_sets, uploaded_files]
          end
        end
      end
    end
  end
end
