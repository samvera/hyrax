module Hyrax
  # Grants edit access for the supplied user for the members attached to a work
  class GrantEditToMembersJob <  Hyrax::ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [ActiveFedora::Base] work - the work object
    # @param [String] user_key - the user to add
    # @param [Boolean] use_valkyrie - use valkyrie objects for this operation?
    def perform(work, user_key, use_valkyrie: Hyrax.config.use_valkyrie?)
      # Iterate over ids because reifying objects is slow.
      file_set_ids(work).each do |file_set_id|
        # Call this synchronously, since we're already in a job
        GrantEditJob.perform_now(file_set_id, user_key, use_valkyrie)
      end
    end

    private

      # Filter the member ids and return only the FileSet ids (filter out child works)
      # @return [Array<String>] the file set ids
      def file_set_ids(work)
        case work
        when ActiveFedora::Base
          ::FileSet.search_with_conditions(id: work.member_ids).map(&:id)
        when Valkyrie::Resource
          Hyrax.query_service.custom_queries.find_child_fileset_ids(resource: work)
        end
      end
  end
end
