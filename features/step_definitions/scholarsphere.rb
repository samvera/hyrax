When /^I attach a file "([^"]*)" to the dynamically created "([^"]*)"$/ do |path, field|
  find(field).native.send_keys(File.expand_path(path, Rails.root))
end

Given /^And I click the anchor "([^"]*)"$/ do |link|
  click_link(link)
end

# tests wether a select option is choosen
Then /^"([^"]*)" should be selected for "([^"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    field_labeled(field).find(:xpath, ".//option[@selected = 'selected'][text() = '#{value}']").should be_present
  end
end

Then /^"([^"]*)" should not be selected for "([^"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    field_labeled(field).find(:xpath, ".//option[@selected = 'selected'][text() = '#{value}']").should_not be_present
  end
end

# checks if a form field is disabled
Then /^"([^\"]*)" should( not)? be disabled$/ do |label, negate|
  element = begin
    find_button(label)
  rescue Capybara::ElementNotFound
    find_field(label)
  end
  ["false", "", nil].send(negate ? :should : :should_not, include(field[:disabled]))
end
