# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds and removes fileset related objects
      class RemoveFileSetRelatedObjects
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          return Success(obj) if obj.member_ids.empty?

          file_sets = obj.member_ids.map { |id| Hyrax.query_service.find_by(id:) }

          file_sets.each do |fs|
            remove_file_metadata(fs)
            Hyrax::Transactions::Container['work_resource.delete_acl'].call(fs)
          end

          Success(obj)
        end

        private

        def remove_file_metadata(file_set)
          file_set[:file_ids].each do |file_id|
            Hyrax::Transactions::Container['file_metadata.destroy'].call(Hyrax.query_service.custom_queries.find_file_metadata_by(id: file_id))
          rescue ::Ldp::Gone
            nil
          end
        end
      end
    end
  end
end
