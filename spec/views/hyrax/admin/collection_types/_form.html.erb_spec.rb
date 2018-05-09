RSpec.describe 'hyrax/admin/collection_types/_form.html.erb', type: :view do
  let(:collection_type) { build(:collection_type) }
  let(:form) { Hyrax::Forms::Admin::CollectionTypeForm.new(collection_type: collection_type) }

  before do
    assign(:form, form)
    assign(:collection_type, collection_type)
  end

  it "has 3 tabs" do
    render
    expect(rendered).to have_selector('#metadata')
    expect(rendered).to have_selector('#settings')
    expect(rendered).to have_selector('#participants')
    expect(rendered).to have_selector('#appearance')
  end

  context "when creating a new collection type" do
    before do
      allow(form).to receive(:persisted?).and_return(false)
    end

    it "only shows the metadata tab" do
      render
      expect(rendered).to have_link(I18n.t('hyrax.admin.collection_types.form.tab.metadata'))
      expect(rendered).not_to have_link(I18n.t('hyrax.admin.collection_types.form.tab.settings'))
      expect(rendered).not_to have_link(I18n.t('hyrax.admin.collection_types.form.tab.participants'))
      expect(rendered).not_to have_link(I18n.t('hyrax.admin.collection_types.form.tab.appearance'))
    end
  end

  context "when editing a collection type" do
    before do
      allow(form).to receive(:persisted?).and_return(true)
    end

    it "shows all three tabs" do
      render
      expect(rendered).to have_link(I18n.t('hyrax.admin.collection_types.form.tab.metadata'))
      expect(rendered).to have_link(I18n.t('hyrax.admin.collection_types.form.tab.settings'))
      expect(rendered).to have_link(I18n.t('hyrax.admin.collection_types.form.tab.participants'))
      expect(rendered).to have_link(I18n.t('hyrax.admin.collection_types.form.tab.appearance'))
    end
  end
end
