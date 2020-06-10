module Hyrax
  # Grants read access for the supplied user for the members attached to a work
  module MembersPermissionJobBehavior
    extend ActiveSupport::Concern

    included do
      queue_as Hyrax.config.ingest_queue_name
    end

    private

    # Filter the member ids and return only the FileSet ids (filter out child works)
    # @return [Array<String>] the file set ids
    def file_set_ids(work)
      case work
      when ActiveFedora::Base
        ::FileSet.search_with_conditions(id: work.member_ids).map(&:id)
      when Valkyrie::Resource
        Hyrax.custom_queries.find_child_fileset_ids(resource: work)
      end
    end

    def use_valkyrie?(work)
      work.is_a? Valkyrie::Resource
    end
  end
end
