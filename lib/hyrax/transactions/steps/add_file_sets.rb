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

        attr_accessor :file_set_batch_size

        ##
        # @param [Class] handler
        # @param [Integer] file_set_batch_size - limit the number of FileSets processed at any given time
        def initialize(handler: Hyrax::WorkUploadsHandler, file_set_batch_size: 1000)
          @handler = handler
          @file_set_batch_size = file_set_batch_size
        end

        ##
        # @param [Hyrax::Work] obj
        # @param [Enumerable<UploadedFile>] uploaded_files
        # @param [Enumerable<Hash>] file_set_params or nil
        #
        # @return [Dry::Monads::Result]
        def call(obj, uploaded_files: [], file_set_params: [])
          return Success(obj) if uploaded_files.empty? && file_set_params.blank? # Skip if no files to attach

          uploaded_files.in_groups_of(file_set_batch_size, false) do |uploaded_file_group|
            @handler.new(work: obj).add(files: uploaded_file_group, file_set_params: file_set_params).attach
          end

          obj = Hyrax.query_service.find_by(id: obj.id)
          obj_file_sets_count = Hyrax.custom_queries.find_child_file_set_ids(resource: obj).size
          update_embargoes_and_leases(obj)
          if uploaded_files.size == obj_file_sets_count
            Success(obj)
          else
            Failure[:failed_to_attach_file_sets, uploaded_files]
          end
        end

        def update_embargoes_and_leases(obj)
          return unless obj.lease || obj.embargo
          # TODO: Find file sets in batches that respect the file_set_batch_size
          # and process in batches
          file_sets = Hyrax.custom_queries.find_child_file_sets(resource: obj)

          Hyrax::LeaseManager.create_or_update_lease_on_members(file_sets, obj) if obj.lease
          Hyrax::EmbargoManager.create_or_update_embargo_on_members(file_sets, obj) if obj.embargo
        end
      end
    end
  end
end
