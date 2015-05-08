module GenericWorkHelper

  def render_collection_links(solr_doc)
    return if solr_doc.collections.empty?
    links = solr_doc.collections.map do |collection|
      link_to collection.title_or_label, collections.collection_path(collection.id)
    end
    content_tag :span, t(:is_part_of) + ': ' + links.join(', ').html_safe
  end

end
