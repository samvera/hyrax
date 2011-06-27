require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'fluid_infusion/_uploader.html.erb' do
  before do
    @controller.template.stubs(:upload_url).returns("/assets/_PID_/file_assets")
  end

  it "should permit locals for container_content_type" do
    render :partial => "fluid_infusion/uploader", :locals => {:container_content_type=>"foo_bar"}
    #response.should have_tag "form.fl-uploader.fl-progEnhance-basic", :action => "/assets/_PID_/file_assets?container_content_type=foo_bar"
    response.should have_tag "form.fl-uploader.fl-progEnhance-basic", :action => "/assets/_PID_/file_assets" do
      with_tag "input#container_content_type", :value => "foo_bar"
    end
  end
  
  it "should permit locals for uploader html_options" do
    render :partial => "fluid_infusion/uploader", :locals => {:html_options=>{:uploader_options => {:accept => "application/pdf"}}}
    response.should have_tag "input#Filedata", :type => "file", :accept=>"application/pdf"
  end

  it "should work with no locals passed in" do
    render
    response.should have_tag  "form.fl-uploader.fl-progEnhance-basic", :action => "/assets/_PID_/file_assets" do
      without_tag "input#container_content_type"
      with_tag "input#Filedata", :type=>"file" do
        without_tag "[accept=?]"
      end
    end
  end
end
