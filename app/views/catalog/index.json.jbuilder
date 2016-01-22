# Overriding Blacklight so that the search results can be displayed in a way compatible with
# tokenInput javascript library.  This is used for suggesting "Related Works" to attach.

json.docs @presenter.documents do |solr_document|
  title = solr_document['title_tesim'].first
  title << " (#{solr_document['human_readable_type_tesim'].first})" if solr_document['human_readable_type_tesim'].present?
  json.pid solr_document['id']
  json.title title
end
