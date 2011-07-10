# This is the post-submission complement to "I fill in the following" from web_steps.rb
Then /^the following (should contain|contain|should not contain|do not contain):$/ do |bool,table|
  # table is a Cucumber::Ast::Table
  if bool == "should contain" || bool == "contain"
    table.rows_hash.each do |name, value|
      Then %{the "#{name}" field should contain "#{value}"}
    end
  elsif bool == "should not contain" || bool == "do not contain"
    table.rows_hash.each do |name, value|
      Then %{the "#{name}" field should not contain "#{value}"}
    end
  else
    pending
  end
end

When /^I select the following(?: within "([^"]*)")?$/ do |scope_selector, table|
  # table is a Cucumber::Ast::Table
  table.rows_hash.each do |field_selector, value|
    Given %{I select "#{value}" from "#{field_selector}" within "#{scope_selector}"}
  end
end

Then /^the following should be selected(?: within "([^"]*)")?$/ do |scope_selector, table|
  # table is a Cucumber::Ast::Table
  table.rows_hash.each do |field_selector, value|
    Then %{"#{value}" should be selected from "#{field_selector}" within "#{scope_selector}"}
    # Then %{the "#{field_selector}" field within "#{scope_selector}" should contain "#{value}"}
  end
end

Then /^"([^"]*)" should be selected from "([^"]*)"(?: within "([^"]*)")?$/ do |value, field_selector, scope_selector|
  # table is a Cucumber::Ast::Table
  with_scope(scope_selector) do
    find_and_check_selected_value(field_selector, value)
  end
end

Then /^I should see a "([^"]*)" button(?: within "([^"]*)")?$/ do |button_locator, scope_selector|
  with_scope(scope_selector) do
    begin
      find_button(button_locator)
    rescue
      raise "no button with value or id or text '#{button_locator}' found"
    end
  end
end

# Find a select tag on the page
# @param [String] locator Capybara locator
# @return [Capybara::Node]
def find_select(locator)
  no_select_msg = "no select box with id, name, or label '#{locator}' found"
  select = find(:xpath, XPath::HTML.select(locator), :message => no_select_msg)
  return select
end

# Find a select tag on the page and test whether the given value is selected within it
# @param [String] locator Capybara locator for the select tag
# @param [String] value the value that should be selected
def find_and_check_selected_value(locator, value)
  select = find_select(locator)
  no_option_msg = "no option with text '#{value}' in select box '#{locator}'"
  option = select.find(:xpath, XPath::HTML.option(value), :message => no_option_msg)
  option.should be_selected
end
