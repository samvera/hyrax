# frozen_string_literal: true

describe 'Batch creation of works', type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "renders the batch create form" do
    visit hyrax.new_batch_upload_path
    expect(page).to have_content "Add New Works by Batch"
    within("li.active") do
      expect(page).to have_content("Files")
    end
    expect(page).to have_content("Each file will be uploaded to a separate new work resulting in one work per uploaded file.")
  end
end
