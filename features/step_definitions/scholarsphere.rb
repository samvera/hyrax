# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
When /^I attach a file "([^"]*)" to the dynamically created "([^"]*)"$/ do |path, field|
  find(field).native.send_keys(File.expand_path(path, Rails.root))
end

Given /^And I click the anchor "([^"]*)"$/ do |link|
  click_link(link)
end

Given /^And I click within the anchor "(.*?)"$/ do |selector|
#Given /^(?:|I )click within the anchor "([^"]*)"$/ do |selector|
  find(selector).click
end

Given /^I have a mail server$/ do
  ContactForm.any_instance.stubs(:deliver).returns(true)
end

Then /^I reset the mail server$/ do
  ContactForm.any_instance.unstub(:deliver)
end

When /^I follow the link within$/ do |selector|
  find(selector).click
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

Given /^I load users$/ do
  FactoryGirl.create(:user)
  FactoryGirl.create(:archivist)
  FactoryGirl.create(:curator)
end

