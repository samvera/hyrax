require 'spec_helper'

describe "Uploading files via web form", :type => :feature do
  before do
    sign_in :user
    click_link "Upload"
  end

  it "should have an ingest screen" do
    expect(page).to have_content "Select files"
    expect(page).to have_content "Start upload"
    expect(page).to have_content "Cancel upload"
    expect(page).to have_xpath '//input[@type="file"]'
  end

  context "the terms of service", :js do
    it "should be required to be checked" do
      attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/image.jp2")
      attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/jp2_fits.xml")
      expect(page).to have_css("button#main_upload_start[disabled]")
      find('#main_upload_start_span').hover
      expect(page).to have_content "Please accept Deposit Agreement before you can upload."
    end
  end
end
