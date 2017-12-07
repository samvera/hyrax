module Hyrax
  module CollectionsHelper
    # TODO: we could move this to CollectionPresenter if it had a view_context
    # @param presenter [Hyrax::CollectionPresenter]
    # @param terms [Array<Symbol>,:all] the list of terms to draw
    def present_terms(presenter, terms = :all, &block)
      terms = presenter.terms if terms == :all
      Hyrax::PresenterRenderer.new(presenter, self).fields(terms, &block)
    end

    def render_collection_links(solr_doc)
      collection_list = Hyrax::CollectionMemberService.run(solr_doc)
      return if collection_list.empty?
      links = collection_list.map do |collection|
        link_to collection.title_or_label, collection_path(collection.id)
      end
      content_tag :span, safe_join([t('hyrax.collection.is_part_of'), ': '] + links)
    end

    # @return [Boolean]
    def has_collection_search_parameters?
      params[:cq].present?
    end

    def button_for_remove_selected_from_collection(collection, label = 'Remove From Collection')
      render 'hyrax/dashboard/collections/button_for_remove_selected_from_collection', collection: collection, label: label
    end
  end
end
