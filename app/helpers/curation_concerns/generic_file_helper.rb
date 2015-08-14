module CurationConcerns::GenericFileHelper
  def generic_file_title(gf)
    can?(:read, gf) ? gf.to_s : 'File'
  end

  def generic_file_link_name(gf)
    can?(:read, gf) ? gf.filename : 'File'
  end

  def parent_path(parent)
    if parent.is_a?(Collection)
      main_app.collection_path(parent)
    else
      polymorphic_path([main_app, :curation_concerns, parent])
    end
  end
end
