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

    # button for removing a batch from a collection
    # @param change_set [Hyrax::CollectionChangeSet] ChangeSet to be updated
    # @param document [SolrDocument]
    # @param label [String] button label
    def button_for_remove_from_collection(change_set, document, label = 'Remove From Collection')
      form_for change_set, url: hyrax.dashboard_collection_path(change_set), method: :put, as: 'collection' do |f|
        single_item_action_remove_form_fields(f, document)
        f.submit label, class: "btn btn-primary collection-remove"
      end
    end

    # button for removing a batch from a collection
    # @param change_set [Hyrax::CollectionChangeSet] ChangeSet to be updated
    # @param label [String] button label
    def button_for_remove_selected_from_collection(change_set, label = 'Remove From Collection')
      form_for change_set, url: hyrax.dashboard_collection_path(change_set.id), method: :put do |f|
        f.hidden_field :members, value: "remove"
        f.submit label, class: "btn btn-primary collection-remove-selected submits-batches"
      end
    end

    # add hidden fields to a form for removing a single document from a collection
    def single_item_action_remove_form_fields(form, document)
      single_item_action_form_fields(form, document, 'remove')
    end

    private

      # add hidden fields to a form for performing an action on a single document on a collection
      def single_item_action_form_fields(form, document, action)
        render 'hyrax/dashboard/collections/single_item_action_fields', form: form, document: document, action: action
      end
  end
end
