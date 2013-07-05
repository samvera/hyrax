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
    str = String.new(helper.help_icon(:tag))
    doc = Nokogiri::HTML(str)
    a = doc.xpath('//a').first
    
    a.attr('data-content').should == "Words or phrases you select to describe what the file is about. These are used to search for content. <em>This is a required field</em>."
    a.attr('data-original-title').should == "Keyword"
    a.attr('id').should == "generic_file_tag_help"
    i = a.children.first
    i.attr('class').should == 'icon-question-sign icon-large'
  end

end


