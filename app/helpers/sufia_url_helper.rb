# TODO: Are these methods still needed?
module SufiaUrlHelper
  def track_generic_work_path(*args)
    track_catalog_path(*args)
  end

  def track_file_set_path(*args)
    track_catalog_path(*args)
  end

  def track_collection_path(*args)
    track_catalog_path(*args)
  end
end
