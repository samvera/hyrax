# @example
#   I log in as "archivist1"
# @example
#   I am logged in as "archivist1"
Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |login|
  email = "#{login}@#{login}.com"
  # Given %{a User exists with a Login of "#{login}"}
  user = User.create(:login => login, :email => email, :password => "password", :password_confirmation => "password")
  User.find_by_login(login).should_not be_nil
  visit logout_path
  visit login_path
  fill_in "Login", :with => login
  fill_in "Password", :with => "password"
  click_button "Login"
  Then %{I should see a link to "my account info" with label "#{login}"} 
  And %{I should see a link to "logout"} 
end

Given /^I am logged in as "([^\"]*)" with "([^\"]*)" permissions$/ do |login,permission_group|
  Given %{I am logged in as "#{login}"}
  RoleMapper.roles(login).should include permission_group
end

Given /^I am a superuser$/ do
  Given %{I am logged in as "BigWig"}
  bigwig_id = User.find_by_login("BigWig").id
  superuser = Superuser.create(:id => 20, :user_id => bigwig_id)
  visit superuser_path
end

Given /^I am not logged in$/ do
  Given %{I log out}
end

Given /^I log out$/ do
  visit '/logout'
end