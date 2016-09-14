require 'spec_helper'

RSpec.describe "The public view of admin sets" do
  let(:admin_set_doc) do
    {
      "system_create_dtsi" => "2016-09-12T19:36:51Z",
      "has_model_ssim" => ["AdminSet"],
      "id" => "w3763695z",
      "title_tesim" => ["A completely unique name"],
      "description_tesim" => ["A substantial description"],
      "thumbnail_path_ss" => "/assets/admin-set-thumb.png",
      "read_access_group_ssim" => ["public"]
    }
  end

  let(:work_doc) do
    {
      "system_create_dtsi" => "2016-09-14T19:36:51Z",
      "has_model_ssim" => ["GenericWork"],
      "id" => "5d86p0402",
      "title_tesim" => ["My member work"],
      "description_tesim" => ["This work belongs to an admin set"],
      "thumbnail_path_ss" => "/assets/work-thumb.png",
      "isPartOf_ssim" => ["w3763695z"],
      "suppressed_bsi" => false,
      "read_access_group_ssim" => ["public"]
    }
  end

  before do
    ActiveFedora::SolrService.add(admin_set_doc)
    ActiveFedora::SolrService.add(work_doc, commit: true)
  end

  scenario do
    visit root_path
    click_link "View all administrative collections"

    # The list of AdminSets
    expect(page).to have_selector "img[src='/assets/admin-set-thumb.png']"
    expect(page).to have_content "09/12/2016"
    expect(page).to have_content "A substantial description"
    click_link "A completely unique name"

    # Show information about the AdminSet
    expect(page).to have_content "A substantial description"
    expect(page).to have_selector "img[src='/assets/admin-set-thumb.png']"

    # Show information about the members
    expect(page).to have_content "Works in this Collection"
    expect(page).to have_selector "img[src='/assets/work-thumb.png']"
    expect(page).to have_link "My member work"
    expect(page).to have_content "09/14/2016"
  end
end
