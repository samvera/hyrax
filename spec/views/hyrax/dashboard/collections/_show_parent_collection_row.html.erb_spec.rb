# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_parent_collection_row.html.erb', type: :view do
  let(:child_collection) { double('Collection', id: '123') }
  let(:parent_collection_doc) do
    { id: '999',
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Title 1"],
      'date_created_tesim' => '2000-01-01' }
  end
  let(:document) { SolrDocument.new(parent_collection_doc) }
  let(:subject) { render('show_parent_collection_row', id: child_collection.id, document: document) }

  context 'when user cannot edit the child collection' do
    before do
      allow(view).to receive(:can?).with(:edit, child_collection.id).and_return(false)
      allow(view).to receive(:can?).with(:edit, document.id).and_return(true)
    end

    it 'does shows link to collection title but not the remove button' do
      subject
      expect(rendered).to have_link(document.title.first)
      expect(rendered).not_to have_button("Remove")
      expect(rendered).not_to have_link("Remove")
    end
  end

  context 'when user can edit the child collection' do
    before do
      allow(view).to receive(:can?).with(:edit, child_collection.id).and_return(true)
    end

    context 'and user can edit the parent collection' do
      before do
        allow(view).to receive(:can?).with(:edit, document.id).and_return(true)
      end

      it 'shows link to collection title and active remove button' do
        subject
        expect(rendered).to have_link(document.title.first)
        expect(rendered).to have_button("Remove")
      end

      it "renders the proper data attributes on list element" do
        expect(subject).to have_selector(:css, 'li[data-post-url="/dashboard/collections/123/remove_parent/999"]')
        expect(subject).to have_selector(:css, 'li[data-id="123"]')
        expect(subject).to have_selector(:css, 'li[data-parent-id="999"]')
      end
    end

    context 'and user cannot edit the parent collection' do
      before do
        allow(view).to receive(:can?).with(:edit, document.id).and_return(false)
      end

      it 'shows link to collection title and active remove link' do
        subject
        expect(rendered).to have_link(document.title.first)
        expect(rendered).to have_link("Remove")
      end
    end
  end
end
