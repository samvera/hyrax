module CurationConcerns::GenericFileHelper

  def generic_file_title(gf)
    can?(:read, gf) ? gf.to_s : "File"
  end

  def generic_file_link_name(gf)
    can?(:read, gf) ? gf.filename : "File"
  end

  def parent_path(parent)
    if parent.is_a?(Collection)
      collection_path(parent)
    else
      polymorphic_path([:curation_concern, parent])
    end
  end
    
end
