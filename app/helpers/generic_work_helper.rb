module GenericWorkHelper
  def render_collection_links(solr_doc)
    collection_list = Sufia::CollectionMemberService.run(solr_doc)
    return if collection_list.empty?
    links = collection_list.map do |collection|
      link_to collection.title_or_label, collection_path(collection.id)
    end
    content_tag :span, t(:is_part_of) + ': ' + links.join(', ').html_safe
  end
end
