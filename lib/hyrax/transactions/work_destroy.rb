# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Destroys a work resource
    #
    # @since 3.0.0
    class WorkDestroy < Transaction
      DEFAULT_STEPS = ['work_resource.delete_all_file_sets',
                       'work_resource.delete_acl',
                       'work_resource.remove_redirect_paths',
                       'work_resource.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end

      ##
      # File sets are destroyed without being removed from the work, so if a
      # later step fails, the surviving work is updated to drop them.
      #
      # @see Hyrax::Transactions::Transaction#call
      def call(resource)
        result = super
        remove_missing_members(resource) if result.failure?
        result
      end

      private

      # Valkyrie::ID defines #== but not #eql?/#hash, so ids are compared as strings.
      def remove_missing_members(resource)
        work = Hyrax.query_service.find_by(id: resource.id)
        found_ids = Hyrax.query_service.find_many_by_ids(ids: work.member_ids).map { |member| member.id.to_s }
        missing_ids = work.member_ids.map(&:to_s) - found_ids
        return if missing_ids.empty?

        unlink_members(work, missing_ids)
        Hyrax.publisher.publish('object.metadata.updated', object: Hyrax.persister.save(resource: work), user: user)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      def unlink_members(work, ids)
        work.member_ids = work.member_ids.reject { |id| ids.include?(id.to_s) }
        work.rendering_ids = work.rendering_ids.reject { |id| ids.include?(id.to_s) } if work.respond_to?(:rendering_ids)
        work.representative_id = nil if ids.include?(work.representative_id.to_s)
        return unless ids.include?(work.thumbnail_id.to_s)
        work.thumbnail = nil if work.respond_to?(:thumbnail)
        work.thumbnail_id = nil
      end

      def user
        Hash(step_arguments_for('work_resource.delete_all_file_sets').last)[:user]
      end
    end
  end
end
