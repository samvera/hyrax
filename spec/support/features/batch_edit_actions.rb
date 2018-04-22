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
      page.find("#generic_work_#{field_id}") # Ensuring that the element is on the page before we fill it
      fill_in "generic_work_#{field_id}", with: "NEW #{field_id}"

      find("##{field_id}_save").click
      # This was `expect(page).to have_content 'Changes Saved'`, however in debugging,
      # the `have_content` check was ignoring the `within` scoping and finding
      # "Changes Saved" for other field areas
      find('.status', text: 'Changes Saved', wait: 5)
    end
  end
end

def batch_edit_expand(field)
  find("#expand_link_#{field}").click
  yield if block_given?
end
