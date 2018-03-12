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
      collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
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

    def button_for_remove_from_collection(collection, document, label: 'Remove From Collection', btn_class: 'btn-primary')
      render 'hyrax/dashboard/collections/button_remove_from_collection', collection: collection, label: label, document: document, btn_class: btn_class
    end

    def button_for_remove_selected_from_collection(collection, label = 'Remove From Collection')
      render 'hyrax/dashboard/collections/button_for_remove_selected_from_collection', collection: collection, label: label
    end

    # add hidden fields to a form for removing a single document from a collection
    def single_item_action_remove_form_fields(form, document)
      single_item_action_form_fields(form, document, 'remove')
    end

    # @param collection_type_gid [String] The gid of the CollectionType to be looked up
    # @return [String] The CollectionType's title if found, else the gid
    def collection_type_label(collection_type_gid)
      CollectionType.find_by_gid!(collection_type_gid).title
    rescue ActiveRecord::RecordNotFound, URI::BadURIError
      CollectionType.find_or_create_default_collection_type.title
    end

    private

      # add hidden fields to a form for performing an action on a single document on a collection
      def single_item_action_form_fields(form, document, action)
        render 'hyrax/dashboard/collections/single_item_action_fields', form: form, document: document, action: action
      end
  end
end
