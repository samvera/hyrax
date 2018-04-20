RSpec.describe 'hyrax/dashboard/collections/_list_collections.html.erb', type: :view do
  let(:subject) { render('list_collections.html.erb', presenter: presenter) }
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(collection_doc) }
  let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, ability) }

  let(:collection_doc) do
    {
      id: '999',
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Title 1"],
      'date_created_tesim' => '2000-01-01'
    }
  end

  before do
    allow(view).to receive(:is_admin_set).and_return(false)
    allow(view).to receive(:current_ability).and_return(ability)
    allow(presenter).to receive(:available_parent_collections).and_return([])
    allow(presenter).to receive(:solr_document).and_return(solr_document)
    allow(presenter).to receive(:allow_batch?).and_return(false)
    allow(presenter).to receive(:collection_type_badge).and_return('A Collection Type')
    allow(presenter).to receive(:total_viewable_items).and_return(3)
    allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)

    stub_template 'hyrax/my/_collection_action_menu.html.erb' => 'actions'
  end

  context 'Managed Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(false)
    end
    context 'show access' do
      context 'for manager' do
        before do
          allow(presenter).to receive(:managed_access).and_return('Manage')
        end
        it "shows Manage access" do
          allow(view).to receive(:current_user).and_return(true)
          render('list_collections.html.erb', collection_presenter: presenter)
          expect(rendered).to have_text('Manage')
        end
      end

      context 'for depositer' do
        before do
          allow(presenter).to receive(:managed_access).and_return('Deposit')
        end
        it "shows Deposit access" do
          allow(view).to receive(:current_user).and_return(true)
          render('list_collections.html.erb', collection_presenter: presenter)
          expect(rendered).to have_text('Deposit')
        end
      end

      context 'for viewer' do
        before do
          allow(presenter).to receive(:managed_access).and_return('Viewer')
        end
        it "shows View access" do
          allow(view).to receive(:current_user).and_return(true)
          render('list_collections.html.erb', collection_presenter: presenter)
          expect(rendered).to have_text('View')
        end
      end
    end
  end

  context 'All Collections' do
    before do
      allow(ability).to receive(:admin?).and_return(true)
      allow(presenter).to receive(:managed_access).and_return('Manage')
    end

    it "doesn't show access" do
      allow(view).to receive(:current_user).and_return(true)
      render('list_collections.html.erb', collection_presenter: presenter)
      expect(rendered).not_to have_text('Manage')
    end
  end
end
