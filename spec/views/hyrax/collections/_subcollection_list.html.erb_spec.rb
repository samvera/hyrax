# frozen_string_literal: true
RSpec.describe 'hyrax/collections/_subcollection_list.html.erb', type: :view do
  let(:subject) { render('subcollection_list', collection: subcollection) }
  let(:collection) { stub_model(Collection, id: '123', title: ['col1']) }

  context 'when subcollection list is empty' do
    let(:subcollection) { nil }

    before do
      assign(:subcollection_docs, subcollection)
    end

    it "posts a warning message" do
      render('subcollection_list', collection: subcollection)
      expect(rendered).to have_text("There are no visible subcollections.")
    end
  end

  context 'when subcollection list is not empty' do
    let(:subcollection) { [collection] }

    before do
      assign(:subcollection_docs, subcollection)
      assign(:document, collection)
      allow(collection).to receive(:title_or_label).and_return(collection.title)
      # make the collection "persisted" so the route returned is valid for show
      allow(collection).to receive(:persisted?).and_return true
      stub_template "hyrax/collections/_paginate" => "<div>paginate</div>"
    end

    it "posts the collection's title with a link to the collection" do
      subject
      expect(rendered).to have_link(collection.title.to_s)
    end

    it 'renders pagination' do
      expect(subject).to render_template("hyrax/collections/_paginate")
    end
  end
end
