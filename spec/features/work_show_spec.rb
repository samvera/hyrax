require 'spec_helper'

describe "display a work as its owner" do
  let(:work) { create(:generic_work, title: ["Magnificent splendor"], user: user) }
  let(:user) { create(:user) }
  let(:work_path) { "/concern/generic_works/#{work.id}" }
  before do
    sign_in user
    visit work_path
  end

  it "shows a work" do
    expect(page).to have_selector 'h1', text: 'Magnificent splendor'

    # Has a form for uploading more files
    expect(page).to have_selector "form#fileupload[action='/concern/container/#{work.id}/file_sets']"

    # and the form redirects back to this page after uploading
    expect(page).to have_selector '#redirect-loc', text: work_path
  end
end
