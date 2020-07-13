# frozen_string_literal: true
RSpec.describe 'hyrax/admin/collection_types/_form_settings.html.erb', type: :view do
  # TODO: add fields as they become available:
  # collection_type_assigns_workflow
  # collection_type_require_membership
  # collection_type_assigns_visibility

  INPUT_IDS = %w[
    collection_type_nestable
    collection_type_brandable
    collection_type_discoverable
    collection_type_sharable
    collection_type_share_applies_to_new_works
    collection_type_allow_multiple_membership
  ].freeze

  let(:collection_type_form) { Hyrax::Forms::Admin::CollectionTypeForm.new(collection_type: collection_type) }
  let(:collection_type) { stub_model(Hyrax::CollectionType) }

  let(:form) do
    view.simple_form_for(collection_type, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    allow(view).to receive(:f).and_return(form)
    allow(form).to receive(:object).and_return(collection_type_form)
  end

  context 'for non-special collection types' do
    context "when collection_type.collections? is false" do
      before do
        allow(collection_type_form).to receive(:collections?).and_return(false)
        render
      end

      it "renders the intructions and warning" do
        expect(rendered).to match(I18n.t("hyrax.admin.collection_types.form_settings.instructions"))
        expect(rendered).to match(I18n.t("hyrax.admin.collection_types.form_settings.warning"))
      end

      INPUT_IDS.each do |id|
        it "renders the #{id} checkbox to be enabled" do
          match = rendered.match(/(<input.*id="#{id}".*)/)
          expect(match).not_to be_nil
          expect(match[1].index('disabled="disabled"')).to be_nil
        end
      end
    end

    context "when collection_type.collections? is true" do
      before do
        allow(collection_type_form).to receive(:collections?).and_return(true)
        assign(:form, collection_type_form)
        allow(view).to receive(:f).and_return(form)
        render
      end

      INPUT_IDS.each do |id|
        it "renders the #{id} checkbox to be disabled" do
          match = rendered.match(/(<input.*id="#{id}".*)/)
          expect(match).not_to be_nil
          expect(match[1].index('disabled="disabled"')).not_to be_nil
        end
      end
    end
  end

  context 'when all_settings_disabled? is true (admin_set or user collection type)' do
    before do
      allow(collection_type_form).to receive(:all_settings_disabled?).and_return(true)
      allow(collection_type_form).to receive(:collections?).and_return(false)
      render
    end

    INPUT_IDS.each do |id|
      it "renders the disabled #{id} checkbox " do
        match = rendered.match(/(<input.*id="#{id}".*)/)
        expect(match).not_to be_nil
        expect(match[1].index('disabled="disabled"')).not_to be_nil
      end
    end
  end
end
