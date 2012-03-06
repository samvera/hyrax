When /^I attach a file "([^"]*)" to the dynamically created "([^"]*)"$/ do |path, field|
  find(field).native.send_keys(File.expand_path(path, __FILE__))
end
