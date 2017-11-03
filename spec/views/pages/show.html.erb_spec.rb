RSpec.describe "hyrax/pages/show", type: :view do
  let(:content_block) { FactoryBot.create(:content_block, name: 'terms_page') }

  before do
    assign(:page, content_block)
    allow(view).to receive(:signed_in?)
    allow(view).to receive(:displayable_content_block)
    allow(view).to receive(:can?).and_return(false)
    stub_template 'catalog/_search_form.html.erb' => ''
    stub_template '_masthead.html.erb' => ''
    render template: 'hyrax/pages/show', layout: 'layouts/homepage'
  end

  it "displays the page name as the document title" do
    expect(rendered).to have_title('Terms of Use')
  end
end
