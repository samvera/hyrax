require 'spec_helper'

describe "Create and use single-use links" do
  include Warden::Test::Helpers
  Warden.test_mode!
  include Sufia::Engine.routes.url_helpers

  before do
    user = User.find_by_email('jilluser@example.com') || FactoryGirl.create(:user)
    
    login_as(user, :scope => :user)

    
    @file = GenericFile.new
    @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file.apply_depositor_metadata(user)
    @file.save
  end

  it "should generate a single-use link to show the record" do
    visit generate_show_single_use_link_path(:id => @file)
    
    expect(page).to have_css '.single-use-link a'
    find('.single-use-link a').click
    expect(page).to have_content 'world.png'
    expect(page).to have_content "Download (can only be used once)"
  end

  it "should download the file contents" do

    visit generate_download_single_use_link_path(:id => @file)

    expect(page).to have_css '.download-link'
    find('.download-link').click
    expected_content = ActiveFedora::Base.find(@file.pid, cast: true).content.content
    expect(page.body).to eq expected_content
  end
end
