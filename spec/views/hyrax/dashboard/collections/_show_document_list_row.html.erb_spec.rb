# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_document_list_row.html.erb', type: :view do
  let(:user) { create(:user) }

  let(:work) do
    build(:monograph,
                    label: 'One Hundred Years of Solitude',
                    date_uploaded: '1999',
                    visibility_setting: 'open',
                    title: 'One Hundred Years of Solitude',
                    depositor: user.user_key,
                    edit_groups: [],
                    creator: ["ggm"])
  end

  let(:solr_doc) { ::SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr) }

  let(:collection) { build(:hyrax_collection, title: 'My awesome collection', members: [work]) }

  context 'when not logged in' do
    before do
      view.blacklight_config = Blacklight::Configuration.new
      assign(:presenter, collection)
      allow(view).to receive(:current_user).and_return(nil)
      allow(view).to receive(:render_other_collection_links).and_return([])
    end

    it "renders collections links" do
      render('show_document_list_row', document: solr_doc)
      expect(rendered).not_to have_content 'My awesome collection'
    end

    it "renders works" do
      render('show_document_list_row', document: solr_doc)
      expect(rendered).to have_content 'One Hundred Years of Solitude'
      expect(rendered).to have_content('Edit Access:')
    end
  end
end
