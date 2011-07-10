require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

# Terms (dt / dd pairs)

Then /^I should see the "([^\"]*)" term$/ do |arg1|
  page.should have_selector("dt", :text=>arg1) 
end

Then /^I should not see the "([^\"]*)" term$/ do |arg1|
  page.should_not have_selector("dt", :text=>arg1) 
end

Then /^the "([^\"]*)" term should contain "([^\"]*)"$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next.should have_selector("dd", :text=>arg2) 
    end
  end
end

Then /^I should see the "([^\"]*)" value$/ do |arg1|
  pending
end

Then /^I should see a link called "([^\"]*)"$/ do |locator|
  find(:xpath, XPath::HTML.link(locator)).should_not be_nil
end

Then /^I should see a link to "([^\"]*)"$/ do |link_path|
  page.should have_xpath(".//a[@href=\"#{path_to(link_path)}\"]")
end

Then /^I should see a link to the "([^\"]*)" page$/ do |link_path|
  page.should have_xpath(".//a[@href=\"#{path_to(link_path)}\"]")
end

Then /^I should see a link to "([^\"]*)" with label "([^\"]*)"$/ do |link_path,link_label|
  page.should have_xpath(".//a[@href=\"#{path_to(link_path)}\"]", :text=>link_label)  
end

Then /^I should not see a link to "([^\"]*)"$/ do |link_path|
  page.should_not have_xpath(".//a[@href=\"#{path_to(link_path)}\"]")
end

Then /^I should not see a link to the "([^\"]*)" page$/ do |link_name|
  page.should_not have_xpath(".//a[@href=\"#{path_to(link_name)}\"]")
end

Then /^related links are displayed as urls$/ do
  pending
end

Then /^I (should|should not) see a delete (field|contributor) button for "([^\"]*)"$/ do |bool,type,target|
  if bool == "should"
    # page.should have_selector("a, :class=>"destructive #{type}", :href=>path_to(target))
    page.should have_xpath(".//a[@href=\"#{path_to(target)}\" and contains(@class, \"destructive\") and contains(@class, \"#{type}\")]")
  else
    # page.should_not have_selector("a", :class=>"destructive #{type}", :href=>path_to(target))
    page.should_not have_xpath(".//a[@href=\"#{path_to(target)}\" and contains(@class, \"destructive\") and contains(@class, \"#{type}\")]")    
  end
end

Then /^I (should|should not) see a button to delete "([^\"]*)" from "([^\"]*)"$/ do |bool,target,container|
  path_name = "#{target} with #{container} as its container"
  if bool == "should"
    # page.should have_selector("a.destroy_file_asset", :href=>path_to(path_name))
    page.should have_xpath(".//a[@href=\"#{path_to(path_name)}\" and @class=\"destroy_file_asset\"]")
  else
    # page.should_not have_selector("a.destroy_file_asset", :href=>path_to(path_name))
    page.should_not have_xpath(".//a[@href=\"#{path_to(path_name)}\" and @class=\"destroy_file_asset\"]")
  end
end

Then /^I (should|should not) see a delete button for "([^\"]*)"$/ do |bool,target|
  if bool == "should"
    # page.should have_selector("a.destructive", :href=>path_to(target))
    page.should have_xpath(".//a[@href=\"#{path_to(target)}\" and @class=\"destructive\"]")
  else
    # page.should_not have_selector("a.destructive", :href=>path_to(target))
    page.should_not have_xpath(".//a[@href=\"#{path_to(target)}\" and @class=\"destructive\"]")
  end
end

