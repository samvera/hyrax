# frozen_string_literal: true
RSpec.describe "hyrax/content_blocks/edit", type: :view do
  before { render }

  it "renders the announcement form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:announcement)), "post" do
      assert_select "textarea#content_block_announcement[name=?]", "content_block[announcement]"
    end
  end

  it "renders the marketing form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:marketing)), "post" do
      assert_select "textarea#content_block_marketing[name=?]", "content_block[marketing]"
    end
  end

  it "renders the researcher form" do
    assert_select "form[action=?][method=?]", hyrax.content_block_path(ContentBlock.for(:researcher)), "post" do
      assert_select "textarea#content_block_researcher[name=?]", "content_block[researcher]"
    end
  end
end
