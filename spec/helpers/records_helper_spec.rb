require 'spec_helper'

describe RecordsHelper, :type => :helper do
  let(:adder) {
    "<button class=\"adder btn\" id=\"additional_test_submit\" name=\"additional_test\"><span aria-hidden=\"true\"><i class=\"glyphicon glyphicon-plus\"></i></span><span class=\"sr-only\">add another test</span></button>"
  }
  let(:remover) {
    "<button class=\"remover btn\" id=\"additional_test_submit\" name=\"additional_test\"><span aria-hidden=\"true\"><i class=\"glyphicon glyphicon-remove\"></i></span><span class=\"sr-only\">add another test</span></button>"    
  }
  it "draws add button" do
    expect(helper.add_field(:test)).to eql(adder)
  end

  it "draws subtract button" do
    expect(helper.subtract_field(:test)).to eql(remover)
  end

  it "draws help_icon" do
    str = String.new(helper.help_icon(:tag))
    doc = Nokogiri::HTML(str)
    a = doc.xpath('//a').first
    expect(a.attr('data-content')).to  eql("Words or phrases you select to describe what the file is about. These are used to search for content. <em>This is a required field</em>.")
    expect(a.attr('data-original-title')).to  eql("Keyword")
    expect(a.attr('id')).to  eql("generic_file_tag_help")
    expect(a.children.first.attr('class')).to eql('help-icon')
  end

  specify "draws help_icon_modal" do
    str = String.new(helper.help_icon_modal('myModal'))
    doc = Nokogiri::HTML(str)
    a = doc.xpath('//a').first
    expect(a.attr('href')).to eq('#myModal')
    expect(a.attr('data-toggle')).to eq('modal')
    expect(a.attr('id')).to eq('generic_file_myModal_help_modal')
    expect(a.children.first.attr('class')).to eq('help-icon')
  end

  describe "download links" do

    before do
      @file = GenericFile.new(id: "fake-1")
      assign :generic_file, @file
    end

    let(:link_text) { helper.render_download_link("Download Fake") }
    let(:icon_text) { helper.render_download_icon("Download the full-sized Fake") }
 
    describe "#render_download_link" do    
      it "has default text" do
        expect(helper.render_download_link).to have_selector("#file_download")
        expect(helper.render_download_link).to have_content("Download")
      end

      it "includes user-supplied link text" do
        expect(link_text).to have_selector("#file_download")
        expect(link_text).to have_content("Download Fake")
      end
    end

    describe "#render_download_icon" do
      it "has default text" do
        expect(helper.render_download_icon).to have_selector("#file_download")
        expect(helper.render_download_icon).to match("Download the document")
      end

      it "includes user-supplied icon text" do
        expect(icon_text).to have_selector("#file_download")
        expect(icon_text).to match("Download the full-sized Fake")
      end
    end

  end

  describe "#metadata_help" do
    specify "default" do
      expect(helper.metadata_help("foo")).to eql("Foo")
    end
    specify "using a key" do
      expect(helper.metadata_help("language")).to eql("The language of the file content.")
    end
  end

  describe "#get_label" do
    specify "default" do
      expect(helper.get_label("foo")).to eql("Foo")
    end
    specify "using a key" do
      expect(helper.get_label("tag")).to eql("Keyword")
    end
  end

  describe "#get_aria_label" do
    specify "default" do
      expect(helper.get_aria_label("foo")).to eql("Usage information for Foo")
    end
    specify "using a key" do
      expect(helper.get_aria_label("tag")).to eql("Usage information for keyword")
    end
  end

end
