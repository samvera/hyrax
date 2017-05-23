RSpec.describe "hyrax/pages/edit", type: :view do
  before { render }

  it "renders the about_page form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.about_page), "post" do
      assert_select "textarea#content_block_about_page[name=?]", "content_block[about_page]"
    end
  end

  it "renders the help_page form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.help_page), "post" do
      assert_select "textarea#content_block_help_page[name=?]", "content_block[help_page]"
    end
  end
end
