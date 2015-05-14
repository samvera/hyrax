require 'spec_helper'

describe 'collections/_show_document_list.html.erb', :type => :view do

  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:collection) { mock_model(Collection) }

  let(:file) do
    gf = GenericFile.new(creator: ["ggm"], title: ['One Hundred Years of Solitude'])
    gf.apply_depositor_metadata(user)
    gf.save
    gf
  end

  let(:documents) {[file]}

  context 'when not logged in' do
    before do
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
      allow(view).to receive(:current_user).and_return(nil)
      allow(file).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
      allow(file).to receive(:edit_people).and_return([])
    end

    it "should render collection" do
      render(partial: 'collections/show_document_list.html.erb', locals: {documents: documents})
      expect(rendered).to have_content 'One Hundred Years of Solitude'
    end
  end

end
