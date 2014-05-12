module ContentBlockHelper

  def editable_content_block(content_block)
    return raw(content_block.value) unless can? :update, content_block
    capture do
      concat content_tag(:div, id: dom_id(content_block, 'preview')) { 
        concat raw(content_block.value) 
        concat button_tag "Edit", class: "btn btn-primary", data: {
          behavior: 'reveal-editor', target: '#' + dom_id(content_block, 'edit')
        }
      } 
      concat form_for([sufia, content_block] ) { |f|
        concat f.text_area :value, id: "text_area_#{content_block.name}", class: "tinymce", rows: 20, cols: 120
        concat f.submit 'Save', class: "btn btn-primary"
      }

      concat tinymce_assets
      concat tinymce
    end
  end
end
