# frozen_string_literal: true
module Hyrax
  module CollectionsHelper # rubocop:disable Metrics/ModuleLength
    ##
    # @since 3.1.0
    # @return [Array<SolrDocument>]
    def available_child_collections(collection:)
      Hyrax::Collections::NestedCollectionQueryService
        .available_child_collections(parent: collection, scope: controller, limit_to_id: nil)
    end

    ##
    # @since 3.1.0
    #
    # @note provides data for handleAddToCollection javascript
    #
    # @return [String] JSON document containing id/title pairs for eligible
    #   parent collections to be displayed in an "Add to Collection" dropdown
    def available_parent_collections_data(collection:)
      Hyrax::Collections::NestedCollectionQueryService
        .available_parent_collections(child: collection, scope: controller, limit_to_id: nil)
        .map do |result|
        { "id" => result.id, "title_first" => result.title.first }
      end.to_json
    end

    ##
    # @since 3.0.0
    # @return [#to_s]
    def collection_metadata_label(collection, field)
      Hyrax::PresenterRenderer.new(collection, self).label(field)
    end

    ##
    # @since 3.0.0
    # @return [#to_s]
    def collection_metadata_value(collection, field)
      Hyrax::PresenterRenderer.new(collection, self).value(field)
    end

    ##
    # @deprecated Use #collection_metadata_label and #collection_metadata_value instead.
    #
    # @param presenter [Hyrax::CollectionPresenter]
    # @param terms [Array<Symbol>,:all] the list of terms to draw
    def present_terms(presenter, terms = :all, &block)
      Deprecation.warn("the .present_terms is deprecated for removal in Hyrax 4.0.0; " \
                       "use #collection_metadata_label/value instead")

      terms = presenter.terms if terms == :all
      Hyrax::PresenterRenderer.new(presenter, self).fields(terms, &block)
    end

    ##
    # @since 3.0.0
    #
    # @see Blacklight::ConfigurationHelperBehavior#active_sort_fields
    def collection_member_sort_fields
      active_sort_fields
    end

    def render_collection_links(solr_doc)
      collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
      return if collection_list.empty?
      links = collection_list.map { |collection| link_to collection.title_or_label, hyrax.collection_path(collection.id) }
      collection_links = []
      links.each_with_index do |link, n|
        collection_links << link
        collection_links << ', ' unless links[n + 1].nil?
      end
      tag.span safe_join([t('hyrax.collection.is_part_of'), ': '] + collection_links)
    end

    def render_other_collection_links(solr_doc, collection_id)
      collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
      return if collection_list.empty?
      links = collection_list.select { |collection| collection.id != collection_id }.map { |collection| link_to collection.title_or_label, hyrax.collection_path(collection.id) }
      return if links.empty?
      collection_links = []
      links.each_with_index do |link, n|
        collection_links << link
        collection_links << ', ' unless links[n + 1].nil?
      end
      tag.span safe_join([t('hyrax.collection.also_belongs_to'), ': '] + collection_links)
    end

    ##
    # Append a collection_type_id to the existing querystring (whether or not it has pre-existing params)
    # @return [String] the original url with and added collection_type_id param
    def append_collection_type_url(url, collection_type_id)
      uri = URI.parse(url)
      uri.query = [uri.query, "collection_type_id=#{collection_type_id}"].compact.join('&')
      uri.to_s
    end

    ##
    # @return [Boolean]
    def collection_search_parameters?
      params[:cq].present?
    end

    ##
    # @deprecated
    # @return [Boolean]
    def has_collection_search_parameters? # rubocop:disable Naming/PredicateName:
      Deprecation.warn('use #collection_search_parameters? helper instead')
      collection_search_parameters?
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

    ##
    # @param collection [Object]
    def collection_type_label_for(collection:)
      CollectionType.for(collection: collection).title
    end

    ##
    # @param collection [Object]
    #
    # @return [Boolean]
    def collection_brandable?(collection:)
      CollectionType.for(collection: collection).brandable?
    end

    ##
    # @param collection [Object]
    #
    # @return [Boolean]
    def collection_discoverable?(collection:)
      CollectionType.for(collection: collection).discoverable?
    end

    ##
    # @param collection [Object]
    #
    # @return [Boolean]
    def collection_sharable?(collection:)
      CollectionType.for(collection: collection).sharable?
    end

    ##
    # @note this helper is primarily intended for use with blacklight facet
    #   fields. it assumes we index a `collection_type_gid` and the helper
    #   can be passed as as a `helper_method:` to `add_facet_field`.
    #
    # @param collection_type_gid [String] The gid of the CollectionType to be looked up
    # @return [String] The CollectionType's title if found, else the gid
    def collection_type_label(collection_type_gid)
      CollectionType.find_by_gid!(collection_type_gid).title
    rescue ActiveRecord::RecordNotFound, URI::InvalidURIError, URI::BadURIError
      CollectionType.find_or_create_default_collection_type.title
    end

    ##
    # @param collection [Object]
    #
    # @return [PermissionTemplateForm]
    def collection_permission_template_form_for(form:)
      case form
      when Valkyrie::ChangeSet
        template_model = Hyrax::PermissionTemplate.find_or_create_by(source_id: form.id.to_s)
        Hyrax::Forms::PermissionTemplateForm.new(template_model)
      else
        form.permission_template
      end
    end

    private

    # add hidden fields to a form for performing an action on a single document on a collection
    def single_item_action_form_fields(form, document, action)
      render 'hyrax/dashboard/collections/single_item_action_fields', form: form, document: document, action: action
    end
  end
end # rubocop:enable Metrics/ModuleLength
