require 'spec_helper'

describe RecordsHelper do
  it "draws add button" do
    helper.add_field(:test).should == 
      "<button class=\"adder btn\" id=\"additional_test_submit\" name=\"additional_test\">+<span class=\"sr-only\">add another test</span></button>"
  end

  it "draws subtract button" do
    helper.subtract_field(:test).should == 
      "<button class=\"remover btn\" id=\"additional_test_submit\" name=\"additional_test\">-<span class=\"sr-only\">add another test</span></button>"
  end

  it "draws help_icon" do
    str = String.new(helper.help_icon(:tag))
    doc = Nokogiri::HTML(str)
    a = doc.xpath('//a').first
    
    a.attr('data-content').should == "Words or phrases you select to describe what the file is about. These are used to search for content. <em>This is a required field</em>."
    a.attr('data-original-title').should == "Keyword"
    a.attr('id').should == "generic_file_tag_help"
    i = a.children.first
    i.attr('class').should == 'glyphicon glyphicon-question-sign large-icon'
  end

  specify "draws help_icon_modal" do
    str = String.new(helper.help_icon_modal('myModal'))
    doc = Nokogiri::HTML(str)
    a = doc.xpath('//a').first

    expect(a.attr('href')).to eq('#myModal')
    expect(a.attr('data-toggle')).to eq('modal')
    expect(a.attr('id')).to eq('generic_file_myModal_help_modal')
    i = a.children.first
    expect(i.attr('class')).to eq('glyphicon glyphicon-question-sign large-icon')
  end

  describe "download links" do

    before :all do
      @file = GenericFile.new(pid: "fake:1")
      assign :generic_file, @file
    end

    describe "#render_download_link" do    
      it "has default text" do
        helper.render_download_link.should have_selector("#file_download")
        helper.render_download_link.should have_content("Download")
      end

      it "includes user-supplied text" do
        content = helper.render_download_link("Download Fake")
        content.should have_selector("#file_download")
        content.should have_content("Download Fake")
      end
    end

    describe "#render_download_icon" do
      it "has default text" do
        helper.render_download_icon.should have_selector("#file_download")
        helper.render_download_icon.should match("Download the document")
      end

      it "includes user-supplied text" do
        content = helper.render_download_icon("Download the full-sized Fake")
        content.should have_selector("#file_download")
        content.should match("Download the full-sized Fake")
      end
    end

  end

end
