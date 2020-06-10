# frozen_string_literal: true
RSpec.describe "hyrax/pages/edit", type: :view do
  before { render }

  it "renders the about form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.for(:about)), "post" do
      assert_select "textarea#content_block_about[name=?]", "content_block[about]"
    end
  end

  it "renders the help form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.for(:help)), "post" do
      assert_select "textarea#content_block_help[name=?]", "content_block[help]"
    end
  end

  it "renders the agreement form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.for(:agreement)), "post" do
      assert_select "textarea#content_block_agreement[name=?]", "content_block[agreement]"
    end
  end

  it "renders the terms form" do
    assert_select "form[action=?][method=?]", hyrax.page_path(ContentBlock.for(:terms)), "post" do
      assert_select "textarea#content_block_terms[name=?]", "content_block[terms]"
    end
  end
end
