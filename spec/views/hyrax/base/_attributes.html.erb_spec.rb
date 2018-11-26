RSpec.describe 'hyrax/base/_attributes.html.erb' do
  let(:creator)     { 'Bilbo' }
  let(:contributor) { 'Frodo' }
  let(:subject)     { 'history' }
  let(:description) { ['Lorem ipsum < lorem ipsum. http://my.link.com'] }

  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    {
      ActiveFedora.index_field_mapper.solr_name('has_model', :symbol) => ["GenericWork"],
      subject_tesim: subject,
      contributor_tesim: contributor,
      creator_tesim: creator,
      description_tesim: description
    }
  end
  let(:ability) { double(admin?: true) }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:doc) { Nokogiri::HTML(rendered) }

  before do
    allow(presenter).to receive(:member_of_collection_presenters).and_return([])
    allow(view).to receive(:dom_class) { '' }

    render 'hyrax/base/attributes', presenter: presenter
  end

  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_link(creator)
    expect(rendered).to have_link(contributor)
    expect(rendered).to have_link(subject)
  end
end
