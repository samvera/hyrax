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
  with_sleep_injector do
    find("#expand_link_#{field}").click
    yield if block_given?
  end
end

# Cribbed from Notre Dame's experience with extensive Capybara testing in our QA_Tests environment.
# https://github.com/ndlib/QA_tests/blob/4e52fa69d5c3fd774febb2bd85134a78d21cbe97/spec/spec_support/inject_sleep.rb#L8-L24
# Capybara makes claims that it's wait will in fact wait for elements to appear. In our experience, this is
# mostly true.
def with_sleep_injector
  yield
rescue Capybara::ElementNotFound
  sleep 3
  begin
    yield
  rescue Capybara::ElementNotFound
    sleep 10
    yield
  end
end
