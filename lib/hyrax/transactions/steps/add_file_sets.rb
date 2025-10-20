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

          uploaded_files.in_groups_of(5, false) do |uploaded_file_group|
            handler = Hyrax::WorkUploadsHandler.new(work: obj).add(files: uploaded_file_group, file_set_params: file_set_params)
            handler.attach
          end

          obj = Hyrax.query_service.find_by(id: obj.id)

          update_embargoes_and_leases(obj)
          if uploaded_files.size == obj.member_ids.size
            Success(obj)
          else
            Failure[:failed_to_attach_file_sets, uploaded_files]
          end
        end

        def update_embargoes_and_leases(obj)
          return unless obj.lease || obj.embargo

          file_sets = obj.member_ids.map do |member|
            found = Hyrax.query_service.find_by(id: member)
            found if found.is_a? Hyrax::FileSet
          end.compact

          # TODO: improve queries - Non performant to perform single queries. Perhaps queries ids then reject.
          Hyrax::LeaseManager.create_or_update_lease_on_members(file_sets, obj) if obj.lease
          Hyrax::EmbargoManager.create_or_update_embargo_on_members(file_sets, obj) if obj.embargo
        end
      end
    end
  end
end
