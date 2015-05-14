require 'spec_helper'

describe 'collections/_show_document_list_row.html.erb', :type => :view do

  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:work) do
    gw = GenericWork.new(creator: ["ggm"], title: ['One Hundred Years of Solitude'])
    gw.apply_depositor_metadata(user)
    gw.save
    gw
  end

  let(:collection) { mock_model(Collection, title: 'My awesome collection', members: [work]) }

  context 'when not logged in' do
    before do
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
      allow(view).to receive(:current_user).and_return(nil)
      allow(work).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
      allow(work).to receive(:edit_people).and_return([])
      allow(view).to receive(:render_collection_links).and_return("collections: #{collection.title}")
    end

    it "should render collections links" do
      render(partial: 'collections/show_document_list_row.html.erb', locals: {document: work})
      expect(rendered).to have_content 'My awesome collection'
    end

    it "should render works" do
      render(partial: 'collections/show_document_list_row.html.erb', locals: {document: work})
      expect(rendered).to have_content 'One Hundred Years of Solitude'
    end
  end
end
