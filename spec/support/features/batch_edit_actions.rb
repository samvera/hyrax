def batch_edit_fields
  # skipping based_near because it's a select2 field, which is hard to test via capybara
  [
    "creator", "contributor", "description", "keyword", "publisher", "date_created",
    "subject", "language", "identifier", "related_url", "resource_type"
  ]
end

def fill_in_batch_edit_field(id)
  batch_edit_expand(id)
  within "#form_#{id}" do
    fill_in "generic_work_#{id}", with: "NEW #{id}"
  end
end

def fill_in_batch_edit_field_and_verify(id)
  within "#form_#{id}" do
    click_button "#{id}_save"
    # Incrementing from 5 to 15 to see if we can prevent erratic failures in Travis. These
    # failures result in a broken build and require a restart of the specs. This restart
    # and waiting for feedback slows the overall trajectory of iterating on Hyrax.
    expect(page).to have_content 'Changes Saved', wait: Capybara.default_max_wait_time * 15
  end
end

def batch_edit_expand(field)
  link = find("#expand_link_#{field}")
  while link["class"].include?("collapsed")
    sleep 0.1
    link.click if link["class"].include?("collapsed")
  end
end

def select_batch_edit_field(id, option)
  batch_edit_expand(id)
  select(option, from: "generic_work_#{id}")
end
