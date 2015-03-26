module SufiaUrlHelper
  def track_generic_file_path(*args)
    track_solr_document_path(*args)
  end

  def track_collection_path(*args)
    track_solr_document_path(*args)
  end
end
