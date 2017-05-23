RSpec.describe "hyrax/content_blocks/edit", type: :view do
  before { render }

  it "renders the announcement_text form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.announcement_text), "post" do
      assert_select "textarea#content_block_announcement_text[name=?]", "content_block[announcement_text]"
    end
  end

  it "renders the marketing_text form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.marketing_text), "post" do
      assert_select "textarea#content_block_marketing_text[name=?]", "content_block[marketing_text]"
    end
  end

  it "renders the featured_researcher form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.featured_researcher), "post" do
      assert_select "textarea#content_block_featured_researcher[name=?]", "content_block[featured_researcher]"
    end
  end
end
