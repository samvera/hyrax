module ContentBlockHelper

  def editable_content_block(content_block)
    return raw(content_block.value) unless can? :update, content_block
    capture do
      concat form_for([sufia, content_block]) { |f|
        concat f.text_area :value, class: "tinymce", rows: 20, cols: 120
        concat f.submit 'Save', class: "btn btn-primary"
      } 

      concat tinymce_assets
      concat tinymce
    end
  end
end
