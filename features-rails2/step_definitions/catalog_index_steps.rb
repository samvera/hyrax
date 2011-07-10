Given /^the following catalog_indices:$/ do |catalog_indices|
  CatalogIndex.create!(catalog_indices.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) catalog_index$/ do |pos|
  visit catalog_indices_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following catalog_indices:$/ do |expected_catalog_indices_table|
  expected_catalog_indices_table.diff!(tableish('table tr', 'td,th'))
end
