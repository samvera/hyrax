require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

Then /^I should see an inline edit containing "([^"]*)"$/ do |arg1|
  page.should have_selector(".editable-text", :content=>arg1)
end

Then /^the "([^\"]*)" inline edit should contain "([^\"]*)"$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("dd span") do |editable|
        editable.should have_selector(".editable-text", :content=>arg2)
      end 
    end
  end
end

Then /^the "([^\"]*)" inline edit should be empty$/ do |arg1|
  page.should have_selector("dt", :text=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("dd .editable-container") do |editable|
        editable.should have_selector(".editable-edit", :content=>nil)
      end 
    end
  end
end

Then /^the "([^\"]*)" inline date edit should contain "([^\"]*)"$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("dd div.date-select") do |editable_date_picker|
        editable_date_picker.should have_selector("input.controlled-date-part", :value=>arg2)
      end 
    end
  end
end

# This was failing on some computers that displayed "selected" instead of "selected='selected'", so we made it an option in the next step definition 
Then /^the "([^\"]*)" dropdown edit should be set to "([^\"]*)"$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("select") do |dropdown|
        dropdown.should have_selector("option", :content=>arg2, :selected=>"selected")
      end
    end
  end
end

Then /^the "([^\"]*)" dropdown edit should contain "([^\"]*)" as an option$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("select") do |dropdown|
        dropdown.should have_selector("option", :content=>arg2)
      end
    end
  end
end

Then /^the "([^\"]*)" inline textarea edit should contain "([^\"]*)"$/ do |arg1, arg2|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("dd ol li.editable_textarea") do |editable_textarea|
        editable_textarea.should have_selector(".flc-inlineEdit-text", :content=>arg2)
      end
    end
  end
end

Then /^the "([^\"]*)" inline textarea edit should be empty$/ do |arg1|
  page.should have_selector("dt", :content=>arg1) do |dt|
    dt.each do |term| 
      term.next_element.should have_selector("dd ol li.editable_textarea") do |editable_textarea|
        editable_textarea.should have_selector(".flc-inlineEdit-text", :content=>nil)
      end
    end
  end
end

