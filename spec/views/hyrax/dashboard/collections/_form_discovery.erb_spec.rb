# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_discovery.html.erb', type: :view do
  let(:f) do
    view.simple_form_for(form, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    allow(form).to receive(:visibility).and_return(visibility)
    allow(view).to receive(:f).and_return(f)
    render
  end

  context 'with AF Collection', :active_fedora do
    let(:collection) { Collection.new }
    let(:form) { Hyrax::Forms::CollectionForm.new(collection, double, double) }

    context "collection has open access" do
      let(:visibility) { 'open' }

      it "check open access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=open][checked]')
      end
    end

    context "collection has authenticated access" do
      let(:visibility) { 'authenticated' }

      it "check authenticated access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=authenticated][checked]')
      end
    end

    context "collection has restricted access" do
      let(:visibility) { 'restricted' }

      it "restricted access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=restricted][checked]')
      end
    end
  end

  context "with PcdmCollection" do
    let(:collection) { Hyrax::PcdmCollection.new }
    let(:form) { Hyrax::Forms::PcdmCollectionForm.new(collection) }

    context "collection has open access" do
      let(:visibility) { 'open' }

      it "check open access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=open][checked]')
      end
    end

    context "collection has authenticated access" do
      let(:visibility) { 'authenticated' }

      it "check authenticated access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=authenticated][checked]')
      end
    end

    context "collection has restricted access" do
      let(:visibility) { 'restricted' }

      it "restricted access is set" do
        expect(rendered).to have_selector('input[type=radio][name="collection[visibility]"][value=restricted][checked]')
      end
    end
  end
end
