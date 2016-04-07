module CurationConcerns::CollectionsHelper
  def collection_modal_id(collectible)
    "#{collectible.to_param.tr(':', '-')}-modal"
  end

  def link_to_select_collection(collectible, opts = {})
    html_class = opts[:class]
    link_to '#', data: { toggle: 'modal', target: '#' + collection_modal_id(collectible) },
                 class: "add-to-collection #{html_class}", title: "Add #{collectible.human_readable_type} to Collection" do
      icon('plus-sign') + ' Add to a Collection'
    end
  end

  # override hydra-collections
  def link_to_remove_from_collection(document, label = 'Remove From Collection')
    collection_id = @collection ? @collection.id : @presenter.id
    link_to collection_path(collection_id, collection: { members: 'remove' },
                                           batch_document_ids: [document.id]), method: :put do
      icon('minus-sign') + ' ' + label
    end
  end

  def icon(type)
    content_tag :span, '', class: "glyphicon glyphicon-#{type}"
  end

  def collection_options_for_select(exclude_item = nil)
    options_for_select(available_collections(exclude_item))
  end

  private

    # return a list of collections for the current user with the exception of the passed in collection
    def available_collections(exclude_item)
      if exclude_item
        collection_options.reject { |n| n.last == exclude_item.id }
      else
        collection_options
      end
    end

    def collection_options
      @collection_options ||= current_users_collections
    end

    # Defaults to returning a list of all collections.
    # If you have implement User.collections, the results of that will be used.
    def current_users_collections
      if current_user.respond_to?(:collections)
        return current_user.collections.map { |c| [c.title.join(', '), c.id] }
      end
      query = ActiveFedora::SolrQueryBuilder
              .construct_query_for_rel(
                has_model: Collection.to_class_uri)
      convert_solr_docs_to_select_options(
        ActiveFedora::SolrService.query(query,
                                        fl: 'title_tesim id',
                                        rows: 1000)
      )
    end

    def convert_solr_docs_to_select_options(results)
      results
        .map { |r| [SolrDocument.new(r).title, r['id']] }
        .sort do |a, b|
          if a.first && b.first
            a.first <=> b.first
          else
            a.first ? -1 : 1
          end
        end
    end
end
