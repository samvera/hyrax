module Hyrax
  # Presents the options for the Collection widget on the create/edit form
  class CollectionOptionsPresenter
    # @param [Hyrax::CollectionsService] service
    def initialize(service)
      @service = service
    end

    # Return Collection selectbox options based on access type
    # @param [Symbol] access :read or :edit
    def select_options(access = :edit)
      option_values = results(access).map do |solr_doc|
        [solr_doc.to_s, solr_doc.id]
      end
      option_values.sort do |a, b|
        if a.first && b.first
          a.first <=> b.first
        else
          a.first ? -1 : 1
        end
      end
    end

    private

      def results(access)
        @service.search_results(access)
      end
  end
end
