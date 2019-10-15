module Hyrax::FileSetHelper
  def parent_path(parent)
    if parent.is_a?(::Collection)
      main_app.collection_path(parent)
    else
      polymorphic_path([main_app, parent])
    end
  end

  # REVIEW: Since this media display could theoretically work for
  #         any object that implements to_s and the Mime Type methods (image? audio? ...),
  #         Should this really be in file_set or could it be in it's own helper class like media_helper?
  def media_display(presenter, locals = {})
    render media_display_partial(presenter),
           locals.merge(file_set: presenter)
  end

  def media_display_partial(file_set)
    'hyrax/file_sets/media_display/' +
      if Hyrax::MimeTypeService.image? file_set.mime_type
        'image'
      elsif Hyrax::MimeTypeService.video? file_set.mime_type
        'video'
      elsif Hyrax::MimeTypeService.audio? file_set.mime_type
        'audio'
      elsif Hyrax::MimeTypeService.pdf? file_set.mime_type
        'pdf'
      elsif Hyrax::MimeTypeService.office_document? file_set.mime_type
        'office_document'
      else
        'default'
      end
  end
  # rubocop:enable Metrics/MethodLength
end
