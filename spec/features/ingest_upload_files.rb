require 'spec_helper'

describe "Uploading files via web form" do

  before do
    sign_in :user
  end

  it "should have an ingest screen" do
    click_link "upload"
    page.should have_content "Select files"
    page.should have_content "Start upload"
    page.should have_content "Cancel upload"
    page.should have_xpath '//input[@type="file"]'
  end

  it "should require checking the terms of service" do
    click_link "upload"
    attach_file("files[]", "spec/fixtures/image.jp2")
    attach_file("files[]", "spec/fixtures/jp2_fits.xml")
    click_button 'Start upload'
    page.should have_content "You must accept the terms of service!"
  end
end
