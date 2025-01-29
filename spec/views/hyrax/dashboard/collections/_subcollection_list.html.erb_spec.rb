# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_subcollection_list.html.erb', type: :view do
  let(:user) { create :user }
  let(:ability) { instance_double("Ability") }
  let(:collection) { stub_model(Collection, id: '123', title: ['col1']) }
  let(:subject) { render('subcollection_list', id: collection.id, collection: subcollection) }

  before do
    allow(view).to receive(:id).and_return(collection.id)
    allow(view).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:can?).with(:edit, collection.id).and_return true
  end

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

    context 'when user has edit access to the collection' do
      before do
        allow(controller).to receive(:can?).with(:edit, collection.id).and_return true
      end

      it "includes link to the collection and remove button" do
        subject
        expect(rendered).to have_link(collection.title.to_s)
        expect(subject).to render_template('_modal_remove_sub_collection')
      end

      it "renders the proper data attributes on list element" do
        expect(subject).to have_selector(:css, 'li[data-post-url="/dashboard/collections/123/remove_child/123"]')
        expect(subject).to have_selector(:css, 'li[data-id="123"]')
      end

      it 'renders pagination' do
        expect(subject).to render_template("hyrax/collections/_paginate")
      end
    end

    context 'when user has no edit access to the collection' do
      before do
        allow(controller).to receive(:can?).with(:edit, collection.id).and_return false
      end

      it "includes link to the collection and no remove button" do
        subject
        expect(rendered).to have_link(collection.title.to_s)
        expect(subject).not_to render_template('_modal_remove_sub_collection')
      end

      it 'renders pagination' do
        expect(subject).to render_template("hyrax/collections/_paginate")
      end
    end
  end
end
