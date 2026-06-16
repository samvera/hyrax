# frozen_string_literal: true

module Hyrax
  ##
  # Prepended onto hydra-editor's +RecordsHelperBehavior+ so that any metadata
  # field declared with `form: { input_type: rich_text }` renders the shared
  # rich-text editor partial, while every other field falls back to the normal
  # field-partial lookup.
  #
  # This covers all edit-field render sites (work form, collection form, file
  # set form, and downstream overrides) through the single
  # +render_edit_field_partial+ entry point, so no view templates need to change.
  #
  # It is engine-agnostic: the partial it renders emits a plain textarea with the
  # `rich-text` class; applications attach their own editor (TinyMCE, etc.) to
  # that hook. No markdown/HTML engine is required here.
  #
  # @see Hyrax::Forms::ResourceForm#input_type
  # @see records/edit_fields/_rich_text
  module RichTextEditFieldBehavior
    def render_edit_field_partial(field_name, locals)
      form = locals[:f]&.object
      if form.respond_to?(:input_type) && form.input_type(field_name).to_s == 'rich_text'
        return render('records/edit_fields/rich_text', locals.merge(key: field_name))
      end

      super
    end
  end
end
