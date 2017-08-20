def batch_edit_fields
  # skipping based_near because it's a select2 field, which is hard to test via capybara
  [
    "creator", "contributor", "description", "keyword", "publisher", "date_created",
    "subject", "language", "identifier", "related_url"
  ]
end

def fill_in_batch_edit_fields_and_verify!
  batch_edit_fields.each do |field_id|
    within "#form_#{field_id}" do
      batch_edit_expand(field_id)
      fill_in "generic_work_#{field_id}", with: "NEW #{field_id}"
      click_button "#{field_id}_save"
      expect(page).to have_content 'Changes Saved'
    end
  end
end

def batch_edit_expand(field)
  find("#expand_link_#{field}").click
  yield if block_given?
end
