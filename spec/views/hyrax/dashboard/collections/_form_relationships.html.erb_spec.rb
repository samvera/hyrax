RSpec.describe 'hyrax/dashboard/collections/_form_relationships.html.erb', type: :view do
  let(:collection) { build(:public_collection) }
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:repository) { double }
  let(:form) { Hyrax::Forms::CollectionForm.new(collection, current_ability, repository) }

  let(:collection1) { build(:collection, title: ['Hello']) }
  let(:collection2) { build(:collection, title: ['World']) }
  let(:collection3) { build(:collection, title: ['Goodnight']) }
  let(:collection4) { build(:collection, title: ['Moon']) }
  let(:collections) { [collection1, collection2] }
  let(:subcollections) { [collection3, collection4] }

  context "parent & sub-collections exist" do
    before do
      assign(:form, form)
      allow(form).to receive(:available_parent_collections).and_return(collections)
      allow(form).to receive(:available_child_collections).and_return(subcollections)
      render
    end

    it "displays parent collections" do
      expect(rendered).to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.collection_is_subcollection_description'))
      expect(rendered).to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.sub_collections_of_collection_description'))
      expect(rendered).to have_link("Hello")
      expect(rendered).to have_link("World")
      expect(rendered).to have_link("Goodnight")
      expect(rendered).to have_link("Moon")
    end
  end

  context "no parent or sub-collections exist" do
    before do
      assign(:form, form)
      allow(form).to receive(:available_parent_collections).and_return([])
      allow(form).to receive(:available_child_collections).and_return([])
      render
    end

    it "does not show parent collection headers" do
      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.collection_is_subcollection_description'))
      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.sub_collections_of_collection_description'))
    end
  end
end
