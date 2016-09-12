require 'spec_helper'

RSpec.describe "The public view of admin sets" do
  let(:admin_set) do
    create(:admin_set, :public, title: ["A completely unique name"],
                                description: ["A substantial description"])
  end

  before do
    create(:work, :public, admin_set: admin_set, title: ["My member work"])
  end

  scenario do
    visit root_path
    click_link "View all administrative collections"
    click_link "A completely unique name"
    expect(page).to have_content "A substantial description"
    expect(page).to have_content "Works in this Collection"
    expect(page).to have_link "My member work"
  end
end
