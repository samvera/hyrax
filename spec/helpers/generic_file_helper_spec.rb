require 'spec_helper'

describe GenericFileHelper do
  it "draws add button" do
    helper.add_field(:test).should == 
      "<button class=\"adder btn\" id=\"additional_test_submit\" name=\"additional_test\">+<span class=\"accessible-hidden\">add another test</span></button>"
  end

  it "draws subtract button" do
    helper.subtract_field(:test).should == 
      "<button class=\"remover btn\" id=\"additional_test_submit\" name=\"additional_test\">-<span class=\"accessible-hidden\">add another test</span></button>"
  end

  it "draws help_icon" do
    helper.help_icon(:tag).should == 
      "<a href=\"#\" data-content=\"Words or phrases you select to describe what the file is about. These are used to search for content. &lt;em&gt;This is a required field&lt;/em&gt;.\" data-original-title=\"Keyword\" id=\"generic_file_tag_help\" rel=\"popover\"><i class=\"icon-question-sign icon-large\"></i></a>"
  end

end


