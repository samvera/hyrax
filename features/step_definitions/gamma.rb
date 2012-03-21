When /^I attach a file "([^"]*)" to the dynamically created "([^"]*)"$/ do |path, field|
  find(field).native.send_keys(File.expand_path(path, Rails.root))
end

Given /^And I click the anchor "([^"]*)"$/ do |link|
  click_link(link)
end

