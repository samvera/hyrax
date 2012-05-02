# @example
#   I log in as "archivist1@example.com"
# @example
#   I am logged in as "archivist1@example.com"
Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |login|
  driver_name = "rack_test_authenticated_header_#{login}".to_s
  Capybara.register_driver(driver_name) do |app|
    Capybara::RackTest::Driver.new(app, headers: { 'REMOTE_USER' => login })
  end
  user = User.create(:login => login)
  User.find_by_login(login).should_not be_nil
  Capybara.current_driver = driver_name
  
  visit "/"
  step %{And I click the anchor "#{login}"} 
  step %{I should see a link to "ingest" with label "upload"}
  step %{I should see a link to "dashboard" with label "my dashboard"}
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
