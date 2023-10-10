# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Destroys a work resource
    #
    # @since 3.0.0
    class WorkDestroy < Transaction
      DEFAULT_STEPS = ['work_resource.delete_acl',
                       'work_resource.delete_file_set_related_objects',
                       'work_resource.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end

      def call(value)
        remove_file_set_related_objects(value)
        super
      end

      private

      def retrieve_file_set_objects(work_obj)
        work_obj.member_ids.map { |id| Hyrax.query_service.find_by(id:) }
      end

      def remove_file_set_related_objects(work_obj)
        file_sets = retrieve_file_set_objects(work_obj)

        file_sets.each do |fs|
          Steps::DeleteAllFileMetadata.new(property: :file_ids).call(fs)
          Steps::DeleteAccessControl.new.call(fs)
        end
      end
    end
  end
end
