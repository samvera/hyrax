require 'spec_helper'

describe "Uploading files via web form" do
  before do
    sign_in :user
    click_link "Upload"
  end

  it "should have an ingest screen" do
    page.should have_content "Select files"
    page.should have_content "Start upload"
    page.should have_content "Cancel upload"
    page.should have_xpath '//input[@type="file"]'
  end

  it "should require checking the terms of service" do
    attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/image.jp2")
    attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/jp2_fits.xml")
    page.should have_css("button#main_upload_start[disabled]")
    find('#main_upload_start_span').hover do
      page.should have_content "Please accept Deposit Agreement before you can upload."
    end
  end
end
