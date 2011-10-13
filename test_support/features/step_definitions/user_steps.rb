# @example
#   I log in as "archivist1@example.com"
# @example
#   I am logged in as "archivist1@example.com"
Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |email|
  # Given %{a User exists with a Login of "#{login}"}
  user = User.create(:email => email, :password => "password", :password_confirmation => "password")
  User.find_by_email(email).should_not be_nil
  visit destroy_user_session_path
  visit new_user_session_path
  fill_in "Email", :with => email 
  fill_in "Password", :with => "password"
  click_button "Sign in"
  Then %{I should see a link to "my account info" with label "#{email}"} 
  And %{I should see a link to "logout"} 
end

Given /^I am logged in as "([^\"]*)" with "([^\"]*)" permissions$/ do |login,permission_group|
  Given %{I am logged in as "#{login}"}
  RoleMapper.roles(login).should include permission_group
end

Given /^I am a superuser$/ do
  Given %{I am logged in as "bigwig@example.com"}
  bigwig_id = User.find_by_email("bigwig@example.com").id
  superuser = Superuser.create(:id => 20, :user_id => bigwig_id)
  visit superuser_path
end

Given /^I am not logged in$/ do
  Given %{I log out}
end

Given /^I log out$/ do
  visit destroy_user_session_path
end
