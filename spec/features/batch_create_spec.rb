# frozen_string_literal: true

RSpec.feature 'Batch creation of works', type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "renders the batch create form" do
    visit hyrax.new_batch_upload_path
    page.assert_text "Add New Works by Batch"
    within("li.active") do
      page.assert_text("Files")
    end
    page.assert_text("Each file will be uploaded to a separate new work resulting in one work per uploaded file.")
  end
end
