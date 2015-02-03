module ContentBlockHelper

  def editable_content_block(content_block, show_new=false)
    return raw(content_block.value) unless can? :update, content_block
    capture do
      concat content_tag(:div, id: dom_id(content_block, 'preview'), class: 'content_block_preview') {
        concat raw(content_block.value) 
        concat edit_button(content_block)
        concat new_button(content_block) if show_new
      } 
      concat edit_form(content_block)
      concat new_form(content_block.name) if show_new
    end
  end

  def edit_button(content_block)
    button_tag "Edit", class: 'btn btn-primary', data: { behavior: 'reveal-editor', target: '#' + dom_id(content_block, 'edit') }
  end

  def new_button(content_block)
    button_tag "New", class: 'btn btn-primary', data: { behavior: 'reveal-editor', target: '#' + 'new_content_block' }
  end

  def edit_form(content_block, editing_field_id=nil)
    editing_field_id ||= "text_area_#{content_block.name}"
    form_for([sufia, content_block], html: { class: 'tinymce-form' }) { |f|
      concat hidden_field_tag 'content_block[name]', content_block.name
      concat f.text_area :value, id: editing_field_id, class: "tinymce", rows: 20, cols: 120
      concat f.label :external_key, content_block.external_key_name
      concat f.text_field :external_key, class: key_field_class(content_block.name)
      concat content_tag(:div) { f.submit 'Save', class: "btn btn-primary" }
    }
  end

  def key_field_class(content_block_type)
    content_block_type == ContentBlock::RESEARCHER ? 'select2-user' : ''
  end

  def new_form(name)
    content_block = ContentBlock.new(name: name)
    edit_form(content_block, "new_#{name}_text_area")
  end

  def tiny_mce_stuff
    capture do
      concat tinymce_assets
      concat tinymce
    end
  end
end
