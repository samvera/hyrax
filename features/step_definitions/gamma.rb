When /^(?:|I )attach the javascript file "([^"]*)" to "([^"]*)"(?: within "([^"]*)")?$/ do |path, field, selector|
  #find("#panda_input").native.send_keys(File.expand_path("../../../../public/awesome.txt", __FILE__))
  find(field).native.send_keys(File.expand_path(path, __FILE__))
  #with_scope(selector) do
  #  attach_file(field, path)
  #end
end
