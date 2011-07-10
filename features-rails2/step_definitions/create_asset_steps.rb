When /^I create a new ([^"]*)$/ do |asset_type|
  visit path_to("new #{asset_type} page")
end

# Given /^I create a new "([^\"]*)"$/ do |asset_type|
#   visit path_to("new #{asset_type} page")
# end
