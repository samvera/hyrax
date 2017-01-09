
describe 'hyrax/collections/_show_document_list.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:collection) { mock_model(Collection) }

  let(:file) do
    FileSet.create(creator: ["ggm"], title: ['One Hundred Years of Solitude']) do |fs|
      fs.apply_depositor_metadata(user)
    end
  end

  let(:documents) { [file] }

  context 'when not logged in' do
    before do
      view.blacklight_config = Blacklight::Configuration.new
      allow(view).to receive(:current_user).and_return(nil)
      allow(file).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
      allow(file).to receive(:edit_people).and_return([])
    end

    it "renders collection" do
      render('hyrax/collections/show_document_list.html.erb', documents: documents)
      expect(rendered).to have_content 'One Hundred Years of Solitude'
      expect(rendered).not_to have_content 'Action'
    end
  end
end
