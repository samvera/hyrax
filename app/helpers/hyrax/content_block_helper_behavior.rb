module Hyrax
  module ContentBlockHelperBehavior
    def displayable_content_block(content_block, **options)
      return if content_block.value.blank?
      content_tag :div, raw(content_block.value), options
    end

    def display_content_block?(content_block)
      content_block.value.present?
    end

    def edit_button(content_block)
      button_tag "Edit", class: 'btn btn-primary', data: { behavior: 'reveal-editor', target: '#' + dom_id(content_block, 'edit') }
    end

    def new_button(_content_block)
      button_tag "New", class: 'btn btn-primary', data: { behavior: 'reveal-editor', target: '#' + 'new_content_block' }
    end

    def edit_form(content_block, editing_field_id = nil)
      editing_field_id ||= "text_area_#{content_block.name}"
      form_for([hyrax, content_block], html: { class: 'tinymce-form' }) do |f|
        concat hidden_field_tag 'content_block[name]', content_block.name
        concat f.text_area :value, id: editing_field_id, class: "tinymce", rows: 20, cols: 120
        concat f.label :external_key, content_block.external_key_name
        concat f.text_field :external_key, class: key_field_class(content_block.name)
        concat content_tag(:div) { f.submit 'Save', class: "btn btn-primary" }
      end
    end

    def key_field_class(content_block_type)
      content_block_type == ContentBlock::RESEARCHER ? 'select2-user' : ''
    end

    def new_form(name)
      content_block = ContentBlock.new(name: name)
      edit_form(content_block, "new_#{name}_text_area")
    end
  end
end
