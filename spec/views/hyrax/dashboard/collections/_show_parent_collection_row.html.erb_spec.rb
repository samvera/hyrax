RSpec.describe 'hyrax/dashboard/collections/_show_parent_collection_row.html.erb', type: :view do
  let(:child_collection) { double('Collection', id: '123') }
  let(:parent_collection_doc) do
    { id: '999',
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Title 1"],
      'date_created_tesim' => '2000-01-01' }
  end
  let(:document) { SolrDocument.new(parent_collection_doc) }
  let(:subject) { render('show_parent_collection_row.html.erb', id: child_collection.id, document: document) }

  context 'when user can edit the parent collection' do
    before do
      stub_template "_modal_remove_from_collection.html.erb" => 'modal'
      allow(view).to receive(:can?).with(:edit, document.id).and_return(true)
    end

    it 'shows link to collection title and active remove button' do
      subject
      expect(rendered).to have_link(document.title.first)
      expect(rendered).to have_button("Remove")
      expect(subject).to render_template("_modal_remove_from_collection")
    end
  end

  context 'disable button if no edit permission' do
    before do
      stub_template "_modal_remove_from_collection.html.erb" => 'modal'
      allow(view).to receive(:can?).with(:edit, document.id).and_return(false)
    end

    it 'shows link to collection title and disabled remove button' do
      subject
      expect(rendered).to have_link(document.title.first)
      expect(rendered).to have_button("Remove", disabled: true)
      expect(subject).to render_template("_modal_remove_from_collection")
    end
  end
end
