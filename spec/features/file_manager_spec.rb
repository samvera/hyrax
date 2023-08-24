# frozen_string_literal: true
RSpec.describe "file manager" do
  let(:user) { FactoryBot.create(:admin) }
  let!(:work) do
    FactoryBot.valkyrie_create(:monograph, :with_member_file_sets, :public,
           title: ["Toothbrush"])
  end
  let(:file_set) do
    Hyrax.query_service.find_members(resource: work).first
  end
  before do
    sign_in user
    visit "/concern/monographs/#{work.id}/file_manager"
  end

  it "looks like a file manager" do
    # has a bulk edit header
    expect(page.html).to include "<h1>#{I18n.t('hyrax.file_manager.link_text')}</h1>"

    # displays each file set's label
    expect(page).to have_selector "input[name='file_set[title][]'][type='text'][value='#{file_set.title.first}']"

    # has a link to edit each file set
    expect(page).to have_selector("a[href='/concern/file_sets/#{file_set.id}']")

    # has a link back to parent
    expect(page).to have_link work.to_s, href: hyrax_monograph_path(id: work.id, locale: :en)

    # has thumbnails for each resource
    # expect(page).to have_selector("img[src='/test/image/path.jpg']")

    # renders a form for each member
    expect(page).to have_selector("#sortable form", count: members.length)

    # renders an input for titles
    expect(page).to have_selector("input[name='file_set[title][]']")

    # renders a resource form for the entire resource
    expect(page).to have_selector("form#resource-form")

    # renders a hidden field for the resource form thumbnail id
    expect(page).to have_selector("#resource-form input[type=hidden][name='generic_work[thumbnail_id]']", visible: false)

    # renders a thumbnail field for each member
    expect(page).to have_selector("input[name='thumbnail_id']", count: members.length)

    # renders a hidden field for the resource form representative id
    expect(page).to have_selector("#resource-form input[type=hidden][name='generic_work[representative_id]']", visible: false)

    # renders a representative field for each member
    expect(page).to have_selector("input[name='representative_id']", count: members.length)
  end
end
