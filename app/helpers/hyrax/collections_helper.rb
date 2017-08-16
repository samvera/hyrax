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
      collection_type_gid
    end

    def banner_file(collection_id)
      # Find Banner filename
      ci = CollectionBrandingInfo.where(collection_id: collection_id.to_s).where(role: "banner")
      # @banner_file = File.split(ci[0].local_path).last unless ci.empty?
      # @banner_file_location = ci[0].local_path unless ci.empty?
      @banner_file_for_display = "/" + ci[0].local_path.split("/")[-4..-1].join("/") unless ci.empty?
    end

    def logo_record(collection_id)
      logo_info = []
      # Find Logo filename, alttext, linktext
      cis = CollectionBrandingInfo.where(collection_id: collection_id.to_s).where(role: "logo")
      return if cis.empty?
      cis.each do |coll_info|
        logo_file = File.split(coll_info.local_path).last
        file_location = "/" + coll_info.local_path.split("/")[-4..-1].join("/") unless logo_file.empty?
        alttext = coll_info.alt_text
        linkurl = coll_info.target_url
        logo_info << { file: logo_file, file_location: file_location, alttext: alttext, linkurl: linkurl }
      end
      logo_info
    end

    private

      # add hidden fields to a form for performing an action on a single document on a collection
      def single_item_action_form_fields(form, document, action)
        render 'hyrax/dashboard/collections/single_item_action_fields', form: form, document: document, action: action
      end
  end
end
