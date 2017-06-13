module Hyrax
  # Revokes edit access for the supplied user for the members attached to a work
  class RevokeEditFromMembersJob < ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [ActiveFedora::Base] work - the work object
    # @param [String] user_key - the user to remove
    def perform(work, user_key)
      # Iterate over ids because reifying objects is slow.
      file_set_ids(work).each do |file_set_id|
        RevokeEditJob.perform_now(file_set_id, user_key)
      end
    end

    private

      # Filter the member ids and return only the FileSet ids (filter out child works)
      # @return [Array<String>] the file set ids
      def file_set_ids(work)
        ::FileSet.search_with_conditions(id: work.member_ids).map(&:id)
      end
  end
end
