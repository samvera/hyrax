# frozen_string_literal: true

module Hyrax
  module Actors
    class OrderedMembersActor
      include Lockable
      attr_reader :ordered_members

      def initialize(ordered_members)
        @ordered_members = ordered_members
      end

      # Adds FileSets to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      # @param [ActiveFedora::Base] work the parent work
      def attach_to_work(work)
        acquire_lock_for(work.id) do
          work.ordered_members = ordered_members
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          work.save
        end
      end

      def run_callback(user)
        ordered_members.each do |file_set|
          Hyrax.config.callback.run(:after_create_fileset, file_set, user)
        end
      end
    end
  end
end
