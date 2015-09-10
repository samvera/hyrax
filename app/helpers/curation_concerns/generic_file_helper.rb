module CurationConcerns::GenericFileHelper
  def parent_path(parent)
    if parent.is_a?(Collection)
      main_app.collection_path(parent)
    else
      polymorphic_path([main_app, :curation_concerns, parent])
    end
  end

  def media_display(generic_file, locals = {})
    render media_display_partial(generic_file),
           locals.merge(generic_file: generic_file)
  end

  def media_display_partial(generic_file)
    'curation_concerns/generic_files/media_display/' +
      if generic_file.image?
        'image'
      elsif generic_file.video?
        'video'
      elsif generic_file.audio?
        'audio'
      elsif generic_file.pdf?
        'pdf'
      elsif generic_file.office_document?
        'office_document'
      else
        'default'
      end
  end
end
