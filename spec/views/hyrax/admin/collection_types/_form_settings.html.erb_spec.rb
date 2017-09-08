RSpec.describe 'hyrax/admin/collection_types/_form_settings.html.erb', type: :view do
  # TODO: add fields as they become available:
  # collection_type_assigns_workflow
  # collection_type_require_membership
  # collection_type_assigns_visibility

  INPUT_IDS = %w[
    collection_type_nestable
    collection_type_discoverable
    collection_type_sharable
    collection_type_allow_multiple_membership
  ].freeze

  let(:collection_type_form) { Hyrax::Forms::Admin::CollectionTypeForm.new }

  let(:form) do
    view.simple_form_for(collection_type, url: '/update') do |fs_form|
      return fs_form
    end
  end

  context 'for non-special collection types' do
    let(:collection_type) { create(:collection_type) }

    context "when collection_type.collections? is false" do
      before do
        collection_type_form.collection_type = collection_type
        allow(collection_type).to receive(:collections?).and_return(false)
        assign(:form, collection_type_form)
        allow(view).to receive(:f).and_return(form)
        render
      end

      it "renders the intructions and warning" do
        expect(rendered).to match(I18n.t("hyrax.admin.collection_types.form_settings.instructions"))
        expect(rendered).to match(I18n.t("hyrax.admin.collection_types.form_settings.warning"))
      end

      INPUT_IDS.each do |id|
        it "renders the #{id} checkbox to be enabled" do
          match = rendered.match(/(<input.*id="#{id}".*>)/)
          expect(match).not_to be_nil
          expect(match[1].index('disabled="disabled"')).to be_nil
        end
      end
    end

    context "when collection_type.collections? is true" do
      before do
        collection_type_form.collection_type = collection_type
        allow(collection_type).to receive(:collections?).and_return(true)
        assign(:form, collection_type_form)
        allow(view).to receive(:f).and_return(form)
        render
      end

      INPUT_IDS.each do |id|
        it "renders the #{id} checkbox to be disabled" do
          match = rendered.match(/(<input.*id="#{id}".*>)/)
          expect(match).not_to be_nil
          expect(match[1].index('disabled="disabled"')).not_to be_nil
        end
      end
    end
  end

  context 'for admin set collection type' do
    let(:collection_type) { build(:admin_set_collection_type) }

    before do
      collection_type_form.collection_type = collection_type
      allow(collection_type).to receive(:collections?).and_return(false)
      assign(:form, collection_type_form)
      allow(view).to receive(:f).and_return(form)
      render
    end

    INPUT_IDS.each do |id|
      it "renders the #{id} checkbox to be disabled" do
        match = rendered.match(/(<input.*id="#{id}".*>)/)
        expect(match).not_to be_nil
        expect(match[1].index('disabled="disabled"')).not_to be_nil
      end
    end
  end

  context 'for user collection type' do
    let(:collection_type) { build(:user_collection_type) }

    before do
      collection_type_form.collection_type = collection_type
      allow(collection_type).to receive(:collections?).and_return(false)
      assign(:form, collection_type_form)
      allow(view).to receive(:f).and_return(form)
      render
    end

    INPUT_IDS.each do |id|
      it "renders the #{id} checkbox to be disabled" do
        match = rendered.match(/(<input.*id="#{id}".*>)/)
        expect(match).not_to be_nil
        expect(match[1].index('disabled="disabled"')).not_to be_nil
      end
    end
  end
end
