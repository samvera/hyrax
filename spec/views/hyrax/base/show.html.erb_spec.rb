RSpec.describe 'hyrax/base/show.html.erb', type: :view do
  let(:solr_document) do
    SolrDocument.new(id: '999',
                     title_tesim: ['Title of the Work'],
                     date_modified_dtsi: '2011-04-01',
                     has_model_ssim: ['GenericWork'])
  end
  let(:ability) { double }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:workflow_presenter) do
    double('workflow_presenter', badge: 'Foobar')
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }
  before do
    allow(presenter).to receive(:workflow).and_return(workflow_presenter)
    stub_template 'hyrax/base/_metadata.html.erb' => ''
    stub_template 'hyrax/base/_relationships.html.erb' => ''
    stub_template 'hyrax/base/_show_actions.html.erb' => ''
    stub_template 'hyrax/base/_representative_media.html.erb' => ''
    stub_template 'hyrax/base/_social_media.html.erb' => ''
    stub_template 'hyrax/base/_citations.html.erb' => ''
    stub_template 'hyrax/base/_items.html.erb' => ''
    stub_template 'hyrax/base/_workflow_actions_widget.html.erb' => ''
    assign(:presenter, presenter)
    render
  end

  it 'shows last saved' do
    expect(page).to have_content 'Last modified: 04/01/2011'
  end

  it 'shows workflow badge' do
    expect(page).to have_content 'Foobar'
  end
end
