# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_actions.html.erb', type: :view do
  let(:solr_document) { double("Solr Doc", id: 'file_set_id') }
  let(:user) { build(:user) }
  let(:ability) { Ability.new(user) }
  let(:file_set) { Hyrax::FileSetPresenter.new(solr_document, ability) }
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(file_set).to receive(:parent).and_return(:parent)
    allow(file_set).to receive(:id).and_return('fake')
    assign(:presenter, parent_presenter)
  end

  context 'with download permission' do
    before do
      allow(view).to receive(:workflow_restriction?).and_return(false)
      allow(view).to receive(:can?).with(:edit, file_set.id).and_return(false)
      allow(view).to receive(:can?).with(:destroy, file_set.id).and_return(false)
      allow(view).to receive(:can?).with(:download, file_set.id).and_return(true)
      render 'hyrax/file_sets/actions', file_set: file_set
    end

    it "includes google analytics data in the download link" do
      expect(rendered).to have_css('a#file_download')
      expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end
  end

  context 'with no permission' do
    before do
      allow(view).to receive(:can?).with(:edit, file_set.id).and_return(false)
      allow(view).to receive(:can?).with(:destroy, file_set.id).and_return(false)
      allow(view).to receive(:can?).with(:download, file_set.id).and_return(false)
      render 'hyrax/file_sets/actions', file_set: file_set
    end

    it "renders nothing" do
      expect(rendered).to eq('')
    end
  end
end
