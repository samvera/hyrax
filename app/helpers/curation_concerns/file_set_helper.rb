module CurationConcerns::FileSetHelper
  def parent_path(parent)
    if parent.is_a?(Collection)
      main_app.collection_path(parent)
    else
      polymorphic_path([main_app, parent])
    end
  end

  def media_display(file_set, locals = {})
    render media_display_partial(file_set),
           locals.merge(file_set: file_set)
  end

  def media_display_partial(file_set)
    'curation_concerns/file_sets/media_display/' +
      if file_set.image?
        'image'
      elsif file_set.video?
        'video'
      elsif file_set.audio?
        'audio'
      elsif file_set.pdf?
        'pdf'
      elsif file_set.office_document?
        'office_document'
      else
        'default'
      end
  end
end
