# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_list_collections.html.erb', type: :view do
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(collection_doc) }
  let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, ability) }

  let(:collection_doc) do
    {
      id: '999',
      'has_model_ssim' => ['Collection'],
      'title_tesim' => ['Title 1'],
      'date_created_tesim' => '2000-01-01'
    }
  end

  before do
    allow(view).to receive(:is_admin_set).and_return(false)
    allow(view).to receive(:current_ability).and_return(ability)
    allow(presenter).to receive(:available_parent_collections).and_return([])
    allow(presenter).to receive(:collection_type_badge).and_return('A Collection Type')
    allow(presenter).to receive(:total_viewable_items).and_return(3)
    allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)

    allow(view)
      .to receive(:available_parent_collections_data)
      .with(collection: presenter)
      .and_return([build(:hyrax_collection)])

    stub_template 'hyrax/my/_collection_action_menu.html.erb' => 'actions'
  end

  context 'Managed Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(false)
      allow(presenter).to receive(:managed_access).and_return('Manage Access')
      render('list_collections', collection_presenter: presenter)
    end

    # NOTE: Real labels are Manage, Deposit, or View, but UI shows whatever label gets returned,
    # so no need to test all conditions.
    it 'shows access label as returned by presenter' do
      expect(rendered).to have_text('Manage Access')
    end
  end

  context 'All Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(true)
      allow(presenter).to receive(:managed_access).and_return('Manage')
      render('list_collections', collection_presenter: presenter)
    end

    it "doesn't show access" do
      expect(rendered).not_to have_text('Manage')
    end
  end
end
