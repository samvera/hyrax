
Then /^I (should|should not) see "([^"]*)" in the file assets list$/ do |bool, arg|
  with_scope("#file_assets") do
    if bool == "should"
      step %{I should see "#{arg}"}
    else
      step %{I should not see "#{arg}"}
    end
  end
end


Then /^I should see a link to "([^"]*)" in the file assets list$/ do |link_name|
  with_scope("#file_assets") do
    step %{I should see a link called "#{link_name}"}
  end
end


Then /^I (should|should not) see a link to "([^"]*)" with label "([^"]*)" in the file assets list$/ do |bool, link_name, label_name|
  with_scope("#file_assets") do
    if bool == "should"
      step %{I should see a link to "#{link_name}" with label "#{label_name}"}
    else
      step %{I should not see a link to "#{link_name}" with label "#{label_name}"} 
    end
  end
end
