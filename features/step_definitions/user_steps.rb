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

require 'hydra-file-access'

# @example
#   I log in as "archivist1@example.com"
# @example
#   I am logged in as "archivist1@example.com"
Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |login|
  # driver_name = "rack_test_authenticated_header_#{login}".to_s
  # Capybara.register_driver(driver_name) do |app|
  #   Capybara::RackTest::Driver.new(app, headers: { 'REMOTE_USER' => login })
  # end
  #Capybara.current_driver = driver_name
  user = User.where(:email=>login).first || FactoryGirl.create(:user, :email=>login)
  User.find_by_user_key(login).should_not be_nil
  visit "/"
  step %{And I click the anchor "Login"} 
  fill_in 'Email', with: login
  fill_in 'Password', with: 'password'
  click_button 'Sign in'
  
  step %{And I click within the anchor "i.icon-user"} 
  step %{I should see a link to "ingest" with label "upload"}
  step %{I should see a link to "dashboard" with label "dashboard"}
  # step %{I should see a link to "logout"} 
end

Given /^I am logged in as "([^\"]*)" with "([^\"]*)" permissions$/ do |login,permission_group|
  Given %{I am logged in as "#{login}"}
  RoleMapper.roles(login).should include permission_group
end

Given /^I am a superuser$/ do
  step %{I am logged in as "bigwig@example.com"}
  bigwig_id = User.find_by_email("bigwig@example.com").id
  superuser = Superuser.create(:id => 20, :user_id => bigwig_id)
  visit superuser_path
end

Given /^I am not logged in$/ do
  step %{I log out}
end

Given /^I log out$/ do
  Capybara.use_default_driver
  visit "/"
end
