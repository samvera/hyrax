RSpec.describe 'hyrax/dashboard/collections/_form_relationships.html.erb', type: :view do
  let(:collection) { create(:collection, id: '1234') }

  let(:collection_type) { double('Hyrax::CollectionType', nestable?: true) }
  let(:ability) { Ability.new(create(:user)) }
  let(:repository) { double }
  # let(:blacklight_config) { double(default_solr_params: nil) }
  let(:form) { Hyrax::Forms::CollectionForm.new(collection, ability, repository) }
  let(:can_deposit) { true }
  let(:can_create_collection_of_type) { true }

  let(:collection1) { build(:collection, title: ['Hello']) }
  let(:collection2) { build(:collection, title: ['World']) }
  let(:collection3) { build(:collection, title: ['Goodnight']) }
  let(:collection4) { build(:collection, title: ['Moon']) }
  let(:collections) { [collection1, collection2] }
  let(:subcollections) { [collection3, collection4] }

  before do
    assign(:form, form)
    allow(form).to receive(:list_parent_collections).and_return([])
    allow(form).to receive(:list_child_collections).and_return([])
    allow(collection).to receive(:collection_type).and_return(collection_type)
    allow(view).to receive(:can?).with(:deposit, collection).and_return(can_deposit)
    allow(view).to receive(:can?).with(:create_collection_of_type, collection_type).and_return(can_create_collection_of_type)
  end

  context "when parent & sub-collections exist" do
    before do
      allow(form).to receive(:list_parent_collections).and_return(collections)
      allow(form).to receive(:list_child_collections).and_return(subcollections)
    end

    it "displays parent collections" do
      stub_template 'hyrax/my/collections/_modal_add_to_collection.html.erb' => 'modal add as subcollection'
      stub_template 'hyrax/my/collections/_modal_add_subcollection.html.erb' => 'modal add as parent'
      stub_template 'modal_remove_from_collection' => 'modal remove parent'
      stub_template 'modal_remove_sub_collection' => 'modal remove subcollection'
      render

      expect(rendered).to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.collection_is_subcollection_description'))
      expect(rendered).to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.sub_collections_of_collection_description'))
      expect(rendered).to have_link("Hello")
      expect(rendered).to have_link("World")
      expect(rendered).to have_link("Goodnight")
      expect(rendered).to have_link("Moon")
    end
  end

  context "when no parent or sub-collections exist" do
    it "does not show parent collection headers" do
      stub_template 'hyrax/my/collections/_modal_add_to_collection.html.erb' => 'modal add as subcollection'
      stub_template 'hyrax/my/collections/_modal_add_subcollection.html.erb' => 'modal add as parent'
      stub_template 'modal_remove_from_collection' => 'modal remove parent'
      stub_template 'modal_remove_sub_collection' => 'modal remove subcollection'
      render

      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.collection_is_subcollection_description'))
      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.sub_collections_of_collection_description'))
    end
  end

  context 'with limited access' do
    let(:can_deposit) { false }
    let(:can_create_collection_of_type) { false }

    it "does not allow show subcollection buttons without access rights" do
      stub_template 'hyrax/my/collections/_modal_add_to_collection.html.erb' => 'modal add as subcollection'
      stub_template 'hyrax/my/collections/_modal_add_subcollection.html.erb' => 'modal add as parent'
      stub_template 'modal_remove_from_collection' => 'modal remove parent'
      stub_template 'modal_remove_sub_collection' => 'modal remove subcollection'
      render

      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.collection_is_subcollection_description'))
      expect(rendered).not_to have_content(I18n.t('hyrax.dashboard.collections.form_relationships.sub_collections_of_collection_description'))
    end
  end
end
